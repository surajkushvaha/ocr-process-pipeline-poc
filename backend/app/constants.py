class Constants:
    APP_NAME = "OCR Process Pipeline"
    VERSION = "1.0.0"
    SUPPORTED_LANGUAGES = ["en", "es", "fr", "de", "zh"]
    MAX_UPLOAD_SIZE_MB = 50
    ALLOWED_FILE_TYPES = ["png", "jpg", "jpeg", "tiff", "pdf"]
    PORT= 5000
    class Routes:
        HOME = "/"
        APP = "/app/<path:path>" #angular paths
        HEALTH = "/health"
        OCR = "/api/ocr"
        UPLOAD = "/api/upload"
        STRUCTURE = "/api/structure"
    
    