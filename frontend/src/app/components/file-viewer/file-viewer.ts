import { Component, inject } from '@angular/core';
import { ApryseViewer } from "./apryse-viewer/apryse-viewer";
import { WebviewerService } from '../../services/webviewer.service';

@Component({
  selector: 'app-file-viewer',
  imports: [ApryseViewer],
  templateUrl: './file-viewer.html',
  styleUrl: './file-viewer.scss',
})
export class FileViewer {
  webviewerService = inject(WebviewerService);
  onChangeFile(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];
      this.webviewerService.loadFile(file);
      // Here you can add logic to load the file into the ApryseViewer
    } else {
      console.log('No file selected');
    }
  }
}
