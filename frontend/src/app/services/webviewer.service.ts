import { Injectable, signal } from '@angular/core';
import { WebViewerInstance } from '@pdftron/webviewer';

@Injectable({
  providedIn: 'root',
})
export class WebviewerService {
  private _webviewerInstance = signal<WebViewerInstance | null>(null);

  setWebviewerInstance(instance: WebViewerInstance) {
    this._webviewerInstance.set(instance);
  }

  get webviewerInstance() {
    return this._webviewerInstance();
  }

  loadFile(file: File) {
    const instance = this._webviewerInstance();
    if (instance) {
      const reader = new FileReader();
      reader.onload = () => {
        const arrayBuffer = reader.result as ArrayBuffer;
        instance.Core.documentViewer.loadDocument(arrayBuffer, { filename: file.name });
      }
      reader.readAsArrayBuffer(file);
    } else {
      console.error('WebViewer instance is not initialized.');
    }
  }
}
