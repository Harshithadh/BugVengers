from flask import Flask, request, jsonify
from PIL import Image
from PIL.ExifTags import TAGS
import os
from werkzeug.utils import secure_filename
from fractions import Fraction
from PIL.TiffImagePlugin import IFDRational

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
            # Try to convert to float if possible
            return float(obj)
        except (ValueError, TypeError):
            # If conversion to float fails, convert to string
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
        lat = convert_gps_coords(gps_info[2], gps_info[1])
        lon = convert_gps_coords(gps_info[4], gps_info[3])
        altitude = gps_info.get(6, None)
        timestamp = gps_info.get(7, None)
        
        # Convert timestamp values to float if they're fractions
        if timestamp:
            timestamp = [float(t) if isinstance(t, (Fraction, IFDRational)) else t for t in timestamp]
        
        # Process raw GPS data to ensure it's JSON serializable
        raw_gps = {}
        for key, value in gps_info.items():
            if isinstance(value, (tuple, list)):
                raw_gps[key] = [make_json_serializable(v) for v in value]
            else:
                raw_gps[key] = make_json_serializable(value)
        
        gps_data = {
            'latitude': round(float(lat), 6),
            'longitude': round(float(lon), 6),
            'altitude': float(altitude) if altitude else None,
            'timestamp': f"{timestamp[0]}:{timestamp[1]}:{timestamp[2]}" if timestamp else None,
            'raw': raw_gps
        }
        return gps_data
    except Exception as e:
        print(f"Error parsing GPS data: {e}")
        return None

def get_image_metadata(image_path):
    try:
        image = Image.open(image_path)
        metadata = {}
        
        # Get basic image information
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

        # Get detailed EXIF data
        if hasattr(image, '_getexif'):
            exif = image._getexif()
            if exif is not None:
                # Create a more organized structure for EXIF data
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
                    
                    # Convert data to JSON serializable format first
                    data = make_json_serializable(data)
                    
                    # Handle different data types
                    if isinstance(data, bytes):
                        try:
                            data = data.decode('utf-8')
                        except UnicodeDecodeError:
                            continue  # Skip binary data that can't be decoded

                    # Organize EXIF data into categories
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

        # Handle ICC profile
        if 'icc_profile' in image.info:
            metadata['color_profile'] = 'ICC Profile Present'

        # Get image statistics if possible
        try:
            stats = image.getextrema()
            metadata['color_stats'] = {
                'extrema': make_json_serializable(stats)
            }
        except Exception:
            pass

        # Get image histogram
        try:
            histogram = image.histogram()
            metadata['histogram'] = make_json_serializable(histogram)
        except Exception:
            pass

        # Print all metadata for debugging
        print("Image Metadata:")
        for key, value in metadata.items():
            print(f"{key}: {value}")

        return metadata
        
    except Exception as e:
        error_msg = f"Error processing image: {str(e)}"
        print(error_msg)
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
        
        # Clean up the uploaded file
        os.remove(filepath)
        
        return jsonify(metadata)
    
    return jsonify({'error': 'Invalid file type'}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000) 