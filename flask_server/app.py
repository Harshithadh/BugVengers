from flask import Flask, request, jsonify
from PIL import Image
from PIL.ExifTags import TAGS
import os
from werkzeug.utils import secure_filename

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
    elif str(type(obj)) == "<class 'PIL.TiffImagePlugin.IFDRational'>":
        return float(obj)
    else:
        return str(obj)

def get_image_metadata(image_path):
    try:
        image = Image.open(image_path)
        metadata = {}
        
        # Get basic image information
        metadata.update({
            'filename': os.path.basename(image_path),
            'format': image.format,
            'mode': image.mode,
            'size': image.size,
            'width': image.width,
            'height': image.height,
            'info': make_json_serializable(dict(image.info)),  # Get all available info
        })

        # Get detailed EXIF data
        if hasattr(image, '_getexif'):
            exif = image._getexif()
            if exif is not None:
                for tag_id in exif:
                    tag = TAGS.get(tag_id, tag_id)
                    data = exif.get(tag_id)
                    
                    # Handle different data types
                    if isinstance(data, bytes):
                        try:
                            data = data.decode('utf-8')
                        except UnicodeDecodeError:
                            data = data.hex()
                    
                    metadata[f'EXIF_{tag}'] = make_json_serializable(data)

        # Get ICC profile if exists
        if 'icc_profile' in image.info:
            metadata['icc_profile'] = 'Present'

        # Get additional PIL image attributes
        additional_attrs = [
            'is_animated',
            'n_frames',
            'palette',
            'layers',
        ]
        
        for attr in additional_attrs:
            if hasattr(image, attr):
                try:
                    value = getattr(image, attr)
                    metadata[attr] = make_json_serializable(value)
                except Exception:
                    pass

        # Get image statistics if possible
        try:
            stats = image.getextrema()
            metadata['color_extrema'] = make_json_serializable(stats)
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