import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ApryseViewer } from './apryse-viewer';

describe('ApryseViewer', () => {
  let component: ApryseViewer;
  let fixture: ComponentFixture<ApryseViewer>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ApryseViewer]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ApryseViewer);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
