import cv2
import pytesseract
from PIL import Image
import spacy
from transformers import pipeline as hf_pipeline
import numpy as np
import os

# Configure pytesseract executable path if it's not in your system's PATH
# pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract' # Example path for Linux

class DocumentPipeline:
    def __init__(self, image_path):
        self.image_path = image_path
        self.image = None
        self.extracted_text = ""
        self.identified_structures = {}
        self.ai_result = None
        # Load spaCy model for Named Entity Recognition (NER)
        self.nlp = spacy.load("en_core_web_sm")
        # Load a Hugging Face pipeline for sentiment analysis (example AI task)
        self.sentiment_analyzer = hf_pipeline("sentiment-analysis")

    def load_image(self):
        """Stage 1: Take input file (image)"""
        if not os.path.exists(self.image_path):
            raise FileNotFoundError(f"File not found at {self.image_path}")
        self.image = cv2.imread(self.image_path)
        if self.image is None:
            raise ValueError("Could not read image file. Check the path and format.")
        print(f"--- Stage 1: Image loaded from {self.image_path}")
        return self

    def perform_ocr(self):
        """Stage 2: Doing OCR"""
        if self.image is None:
            raise RuntimeError("Image not loaded. Run load_image first.")
        
        # Use Pillow (PIL) for better compatibility with pytesseract
        rgb_image = cv2.cvtColor(self.image, cv2.COLOR_BGR2RGB)
        pil_image = Image.fromarray(rgb_image)
        self.extracted_text = pytesseract.image_to_string(pil_image)
        print("--- Stage 2: OCR performed. Extracted text sample:")
        print(f"{self.extracted_text[:200]}...")
        return self

    def identify_structures(self):
        """Stage 3: Identify structures (e.g., named entities) using NLP"""
        if not self.extracted_text:
            raise RuntimeError("No text extracted. Run perform_ocr first.")

        doc = self.nlp(self.extracted_text)
        # Extracting entities as an example of structure identification
        entities = [(ent.text, ent.label_) for ent in doc.ents]
        self.identified_structures['entities'] = entities
        print("--- Stage 3: Structure identification (NER) performed.")
        print(f"Identified entities: {entities[:5]}...")
        return self

    def perform_ai_operation(self):
        """Stage 4: Perform AI operation (e.g., sentiment analysis on the text)"""
        if not self.extracted_text:
            raise RuntimeError("No text extracted. Run perform_ocr first.")
        
        # Hugging Face pipeline works well with lists of short texts
        # Simple approach for demonstration:
        short_text = self.extracted_text[:512] # Truncate for efficiency if text is long
        result = self.sentiment_analyzer(short_text)
        self.ai_result = result[0]
        print("--- Stage 4: AI Operation (Sentiment Analysis) performed.")
        print(f"Sentiment result: {self.ai_result}")
        return self

    def run_pipeline(self):
        """Orchestrates the pipeline flow"""
        (self.load_image()
         .perform_ocr()
         .identify_structures()
         .perform_ai_operation())
        print("--- Pipeline execution complete.")
        return self.ai_result

# Example Usage:
if __name__ == "__main__":
    # Create a dummy image for testing (replace with your file)
    # img = np.zeros((100, 400, 3), dtype=np.uint8)
    # cv2.putText(img, "Hello World, this is a test document.", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    # cv2.imwrite("sample_document.png", img)
    
    # Use an existing file name
    input_file_name = "main.png" 

    try:
        pipeline = DocumentPipeline(image_path=input_file_name)
        pipeline.run_pipeline()
    except Exception as e:
        print(f"An error occurred during pipeline execution: {e}")

