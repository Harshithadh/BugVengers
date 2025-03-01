from flask import Flask, request, jsonify, send_file
from PIL import Image
from PIL.ExifTags import TAGS
import os
from werkzeug.utils import secure_filename
from fractions import Fraction
from PIL.TiffImagePlugin import IFDRational
from datetime import datetime
import piexif
import json
import io
import base64

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def make_json_serializable(obj):
    if isinstance(obj, (str, int, float, bool, type(None))):
        return obj
    elif isinstance(obj, (list, tuple)):
        return [make_json_serializable(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: make_json_serializable(value) for key, value in obj.items()}
    elif isinstance(obj, (IFDRational, Fraction)):
        try:
            return float(obj)
        except (ValueError, TypeError):
            return str(obj)
    else:
        try:
            return float(obj)
        except (ValueError, TypeError):
            return str(obj)

def convert_gps_coords(coords, ref):
    decimal_degrees = coords[0] + coords[1] / 60 + coords[2] / 3600
    if ref in ['S', 'W']:
        decimal_degrees = -decimal_degrees
    return decimal_degrees

def format_gps_data(gps_info):
    if not gps_info:
        return None

    try:
        lat_ref = gps_info.get(1, 'N')
        lat = gps_info.get(2)
        lon_ref = gps_info.get(3, 'E')
        lon = gps_info.get(4)
        alt = gps_info.get(6)
        timestamp = gps_info.get(7)

        if lat and lon:
            lat_value = convert_gps_coords(lat, lat_ref)
            lon_value = convert_gps_coords(lon, lon_ref)
            
            gps_data = {
                'latitude': round(float(lat_value), 6),
                'longitude': round(float(lon_value), 6),
                'altitude': float(alt) if alt else None,
                'timestamp': f"{timestamp[0]}:{timestamp[1]}:{timestamp[2]}" if timestamp else None,
                'raw': {}
            }

            # Preserve all raw GPS data
            for key, value in gps_info.items():
                if isinstance(value, (tuple, list)):
                    gps_data['raw'][key] = [make_json_serializable(v) for v in value]
                else:
                    gps_data['raw'][key] = make_json_serializable(value)

            return gps_data
    except Exception as e:
        print(f"Error parsing GPS data: {e}")
        return None

def get_image_metadata(image_path):
    try:
        image = Image.open(image_path)
        metadata = {}
        
        metadata.update({
            'filename': os.path.basename(image_path),
            'format': image.format,
            'mode': image.mode,
            'size': {
                'width': image.width,
                'height': image.height,
                'resolution': image.size
            }
        })

        if hasattr(image, '_getexif'):
            exif = image._getexif()
            if exif is not None:
                organized_exif = {
                    'device': {},
                    'image': {},
                    'photo': {},
                    'gps': {},
                    'other': {}
                }

                # Define tag mappings
                device_tags = ['Make', 'Model', 'Software']
                image_tags = ['ImageWidth', 'ImageLength', 'BitsPerSample', 'Compression']
                photo_tags = [
                    'DateTimeOriginal', 'CreateDate', 'ExposureTime', 'FNumber', 
                    'ISOSpeedRatings', 'ShutterSpeedValue', 'ApertureValue', 
                    'BrightnessValue', 'ExposureBiasValue', 'FocalLength'
                ]

                for tag_id in exif:
                    try:
                        tag = TAGS.get(tag_id, tag_id)
                        data = exif.get(tag_id)
                        
                        data = make_json_serializable(data)
                        
                        if isinstance(data, bytes):
                            try:
                                data = data.decode('utf-8')
                            except UnicodeDecodeError:
                                continue

                        # Map to appropriate category
                        if tag in device_tags:
                            organized_exif['device'][tag] = data
                        elif tag in image_tags:
                            organized_exif['image'][tag] = data
                        elif tag in photo_tags:
                            organized_exif['photo'][tag] = data
                        elif tag == 'GPSInfo':
                            gps_data = format_gps_data(data)
                            if gps_data:
                                organized_exif['gps'] = gps_data
                        else:
                            organized_exif['other'][tag] = data
                    except Exception as e:
                        print(f"Error processing tag {tag_id}: {str(e)}")
                        continue

                metadata['exif'] = organized_exif

        if 'icc_profile' in image.info:
            metadata['color_profile'] = 'ICC Profile Present'

        try:
            stats = image.getextrema()
            metadata['color_stats'] = {
                'extrema': make_json_serializable(stats)
            }
        except Exception:
            pass

        try:
            histogram = image.histogram()
            metadata['histogram'] = make_json_serializable(histogram)
        except Exception:
            pass

        return metadata
        
    except Exception as e:
        print(f"Error processing image metadata: {str(e)}")
        return None

def preserve_metadata_structure(image_path):
    """Get metadata in the original format after modification"""
    try:
        image = Image.open(image_path)
        metadata = {}
        
        metadata.update({
            'filename': os.path.basename(image_path),
            'format': image.format,
            'mode': image.mode,
            'size': {
                'width': image.width,
                'height': image.height,
                'resolution': image.size
            }
        })

        if hasattr(image, '_getexif'):
            exif = image._getexif()
            if exif is not None:
                organized_exif = {
                    'device': {},
                    'image': {},
                    'photo': {},
                    'gps': {},
                    'other': {}
                }

                for tag_id in exif:
                    tag = TAGS.get(tag_id, tag_id)
                    data = exif.get(tag_id)
                    
                    data = make_json_serializable(data)
                    
                    if isinstance(data, bytes):
                        try:
                            data = data.decode('utf-8')
                        except UnicodeDecodeError:
                            continue  
                    if tag in ['Make', 'Model', 'Software']:
                        organized_exif['device'][tag] = data
                    elif tag in ['ImageWidth', 'ImageLength', 'BitsPerSample', 'Compression']:
                        organized_exif['image'][tag] = data
                    elif tag in ['DateTimeOriginal', 'CreateDate', 'ExposureTime', 'FNumber', 'ISOSpeedRatings']:
                        organized_exif['photo'][tag] = data
                    elif tag == 'GPSInfo':
                        organized_exif['gps'] = format_gps_data(data)
                    else:
                        organized_exif['other'][tag] = data

                metadata['exif'] = organized_exif

        if 'icc_profile' in image.info:
            metadata['color_profile'] = 'ICC Profile Present'

        try:
            stats = image.getextrema()
            metadata['color_stats'] = {
                'extrema': make_json_serializable(stats)
            }
        except Exception:
            pass

        try:
            histogram = image.histogram()
            metadata['histogram'] = make_json_serializable(histogram)
        except Exception:
            pass

        return metadata
        
    except Exception as e:
        error_msg = f"Error processing image: {str(e)}"
        return {'error': error_msg}

@app.route('/get_meta_data', methods=['POST'])
def get_meta_data():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        metadata = get_image_metadata(filepath)
        
        # os.remove(filepath)
        # print(metadata)
        return jsonify(metadata)
    
    return jsonify({'error': 'Invalid file type'}), 400

@app.route('/modify_metadata', methods=['POST'])
def modify_metadata():
    filepath = None
    output_filepath = None
    
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        image_file = request.files['image']
        if image_file.filename == '' or not allowed_file(image_file.filename):
            return jsonify({'error': 'Invalid file'}), 400

        # Get the modifications JSON
        try:
            data = json.loads(request.form.get('modifications', '{}'))
            # Extract the metadata modifications from the nested structure
            modifications = data.get('metadata', {}).get('exif', {})
        except json.JSONDecodeError as e:
            return jsonify({'error': f'Invalid modifications JSON: {str(e)}'}), 400

        # Save original image temporarily
        filename = secure_filename(image_file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        output_filepath = os.path.join(app.config['UPLOAD_FOLDER'], f'modified_{filename}')
        image_file.save(filepath)

        # Open image and get existing EXIF data
        image = Image.open(filepath)
        existing_exif = image._getexif() if hasattr(image, '_getexif') else {}
        
        # Convert existing EXIF to piexif format
        exif_dict = {
            '0th': {},
            '1st': {},
            'Exif': {},
            'GPS': {},
            'Interop': {}
        }

        # Map the existing EXIF data to piexif format
        if existing_exif:
            for tag_id, value in existing_exif.items():
                try:
                    if tag_id in piexif.ImageIFD.__dict__.values():
                        exif_dict['0th'][tag_id] = value
                    elif tag_id in piexif.ExifIFD.__dict__.values():
                        exif_dict['Exif'][tag_id] = value
                    elif tag_id in piexif.GPSIFD.__dict__.values():
                        exif_dict['GPS'][tag_id] = value
                except:
                    continue

        # Update EXIF with modifications
        if 'device' in modifications:
            device = modifications['device']
            if 'Make' in device:
                exif_dict['0th'][piexif.ImageIFD.Make] = device['Make'].encode('utf-8')
            if 'Model' in device:
                exif_dict['0th'][piexif.ImageIFD.Model] = device['Model'].encode('utf-8')
            if 'Software' in device:
                exif_dict['0th'][piexif.ImageIFD.Software] = device['Software'].encode('utf-8')

        if 'photo' in modifications:
            photo = modifications['photo']
            for key, value in photo.items():
                try:
                    if key == 'DateTimeOriginal':
                        exif_dict['Exif'][piexif.ExifIFD.DateTimeOriginal] = value.encode('utf-8')
                    elif key == 'ExposureTime':
                        exif_dict['Exif'][piexif.ExifIFD.ExposureTime] = (int(value * 1000000), 1000000)
                    elif key == 'FNumber':
                        exif_dict['Exif'][piexif.ExifIFD.FNumber] = (int(value * 10), 10)
                    elif key == 'ISOSpeedRatings':
                        exif_dict['Exif'][piexif.ExifIFD.ISOSpeedRatings] = value
                    # Add other photo attributes as needed
                except Exception as e:
                    print(f"Error setting photo attribute {key}: {str(e)}")

        if 'gps' in modifications:
            gps = modifications['gps']
            if 'latitude' in gps and 'longitude' in gps:
                try:
                    lat = float(gps['latitude'])
                    lon = float(gps['longitude'])
                    
                    lat_deg = int(abs(lat))
                    lat_min = int((abs(lat) - lat_deg) * 60)
                    lat_sec = int(((abs(lat) - lat_deg) * 60 - lat_min) * 60 * 100)
                    
                    lon_deg = int(abs(lon))
                    lon_min = int((abs(lon) - lon_deg) * 60)
                    lon_sec = int(((abs(lon) - lon_deg) * 60 - lon_min) * 60 * 100)
                    
                    exif_dict['GPS'][piexif.GPSIFD.GPSLatitudeRef] = 'N' if lat >= 0 else 'S'
                    exif_dict['GPS'][piexif.GPSIFD.GPSLatitude] = [(lat_deg, 1), (lat_min, 1), (lat_sec, 100)]
                    exif_dict['GPS'][piexif.GPSIFD.GPSLongitudeRef] = 'E' if lon >= 0 else 'W'
                    exif_dict['GPS'][piexif.GPSIFD.GPSLongitude] = [(lon_deg, 1), (lon_min, 1), (lon_sec, 100)]
                    
                    if 'altitude' in gps:
                        exif_dict['GPS'][piexif.GPSIFD.GPSAltitude] = (int(float(gps['altitude']) * 100), 100)
                except Exception as e:
                    print(f"Error setting GPS data: {str(e)}")

        try:
            # Create new exif data
            exif_bytes = piexif.dump(exif_dict)
            # Save modified image while preserving quality
            image.save(output_filepath, 'jpeg', quality=95, exif=exif_bytes)
        except Exception as e:
            print(f"Error saving with EXIF: {str(e)}")
            image.save(output_filepath, 'jpeg', quality=95)

        # Get metadata in original format
        metadata = get_image_metadata(output_filepath)

        # Read the modified image
        with open(output_filepath, 'rb') as img_file:
            modified_image = img_file.read()

        # Return both image and metadata
        response = {
            'metadata': metadata,
            'image': base64.b64encode(modified_image).decode('utf-8')
        }
        return jsonify(response)

    except Exception as e:
        print(f"Modification error: {str(e)}")
        return jsonify({'error': f'Error modifying metadata: {str(e)}'}), 500
    finally:
        # Clean up temporary files
        if filepath and os.path.exists(filepath):
            try:
                os.remove(filepath)
            except:
                pass
        if output_filepath and os.path.exists(output_filepath):
            try:
                os.remove(output_filepath)
            except:
                pass

if __name__ == '__main__':
    app.run(port=6000) 