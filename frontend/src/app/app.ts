import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { provideIcons } from '@ng-icons/core';
import { lucideChevronLeft, lucideChevronRight, lucideCloud, lucideLibrary } from '@ng-icons/lucide';
import { Sidebar } from "./components/sidebar/sidebar";
import { Navbar } from "./components/navbar/navbar";

@Component({
  selector: 'app-root',
  imports: [Sidebar, RouterOutlet, Navbar],
  templateUrl: './app.html',
  styleUrl: './app.scss',
  providers: [provideIcons({ lucideCloud, lucideLibrary, lucideChevronLeft, lucideChevronRight })],
})
export class App {
  protected readonly title = signal('frontend');
}
