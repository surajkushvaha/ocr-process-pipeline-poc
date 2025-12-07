import { TestBed } from '@angular/core/testing';

import { WebviewerService } from './webviewer.service';

describe('WebviewerService', () => {
  let service: WebviewerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(WebviewerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
