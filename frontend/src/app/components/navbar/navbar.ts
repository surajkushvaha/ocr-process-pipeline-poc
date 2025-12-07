import { Component, computed, inject  } from '@angular/core';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { lucideChevronLeft, lucideChevronRight, lucideCloud } from '@ng-icons/lucide';
import { HlmButtonImports } from '@spartan-ng/helm/button';
import { HlmIcon } from '@spartan-ng/helm/icon';
import { HlmSidebarImports, HlmSidebarService } from '@spartan-ng/helm/sidebar';

@Component({
  selector: 'app-navbar',
  imports: [NgIcon, HlmSidebarImports, HlmIcon, HlmButtonImports],
  templateUrl: './navbar.html',
  styleUrl: './navbar.scss',
  providers: [provideIcons({ lucideChevronLeft, lucideChevronRight })],
})
export class Navbar {
  sidebarService = inject(HlmSidebarService);
  protected readonly isSidebarCollapsed = computed(() => this.sidebarService.open());
}
