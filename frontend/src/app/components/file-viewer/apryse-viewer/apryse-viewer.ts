import { Component, ElementRef, signal, viewChild, inject } from '@angular/core';
import WebViewer, { WebViewerInstance } from '@pdftron/webviewer';
import { WebviewerService } from '../../../services/webviewer.service';
@Component({
  selector: 'app-apryse-viewer',
  imports: [],
  templateUrl: './apryse-viewer.html',
  styleUrl: './apryse-viewer.scss',
})
export class ApryseViewer {
  webviewerService = inject(WebviewerService);
  viewer = viewChild.required<ElementRef<HTMLElement>>('viewer');
  ngAfterViewInit() {
    this.initializeWebViewer(this.viewer().nativeElement);
  }

  private async initializeWebViewer(container: HTMLElement) {
    WebViewer({
      path: 'public/webviewer',
    },container).then((instance) => {
      this.webviewerService.setWebviewerInstance(instance);
    });
  }


}
