import { Component } from '@angular/core';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { lucideCloud, lucideHouse, lucideFolder, lucideList, lucideFolderHeart, lucideLayoutDashboard, lucideSettings, lucideUser, lucideSettings2, lucidePower, lucideLibrary, lucideBook, lucideBookmark, lucideChevronDown, lucideHistory, lucideLayers, lucideBriefcase, lucideGrid, lucideLayoutGrid, lucideFiles, lucideFile } from '@ng-icons/lucide';
import { RouterLink } from "@angular/router";
import { HlmSidebarImports } from '@spartan-ng/helm/sidebar';

// Base properties shared by all sidebar items
interface BaseSidebarItem {
  title: string;
  icon: string;
}

// Item with sub-items (section header) - no route or onClick
interface SidebarSection extends BaseSidebarItem {
  subItems: SidebarItem[];
  route?: never;
  onClick?: never;
  expandable?: boolean;
  expanded?: boolean;
}

// Item with route (navigation link)
interface SidebarRouteItem extends BaseSidebarItem {
  route: string;
  subItems?: never;
  onClick?: never;
  expandable?: never;
  expanded?: never;
}

// Item with onClick handler
interface SidebarClickItem extends BaseSidebarItem {
  onClick: () => void;
  route?: never;
  subItems?: never;
  expandable?: never;
  expanded?: never;
}

// Union type for all sidebar items
export type SidebarItem = SidebarSection | SidebarRouteItem | SidebarClickItem;
export interface SidebarConfig {
  brandName: string;
  logoPath: string;
  route: string;
  menuItems: SidebarItem[];
}

@Component({
  selector: 'app-sidebar',
  imports: [NgIcon, RouterLink, HlmSidebarImports],
  templateUrl: './sidebar.html',
  styleUrl: './sidebar.scss',
  providers: [provideIcons({
    lucideCloud, lucideUser,lucideFile, lucideSettings, lucideBriefcase, lucideLayers , lucideSettings2, lucideLayoutGrid, lucideFolder, lucideList, lucideFolderHeart, lucidePower, lucideChevronDown,
    lucideBookmark,
    lucideHistory,
    lucideBook,
    lucideLibrary
  })],
})
export class Sidebar {
  sidebarItems: SidebarConfig = {
    brandName: 'My Brand',
    logoPath: 'favicon.ico',
    route: '/dashboard',
    menuItems: [
      {
        title: 'Dashboard',
        icon: 'lucideLayoutGrid',
        route: '/dashboard',
      },
      {
        title: 'Projects',
        icon: 'lucideBriefcase',
        route: '/projects',
      },
      {
        title: 'Documents',
        icon: 'lucideFile',
        route: '/documents',
      },
      {
        title: 'Settings',
        icon: 'lucideSettings',
        route: '/settings',
      },
      {
        title: 'Profile',
        icon: 'lucideUser',
        route: '/settings/profile',
      },
      {
        title: 'Preferences',
        icon: 'lucideSettings2',
        route: '/settings/preferences',
      },
      {
        title: 'Logout',
        icon: 'lucidePower',
        onClick: () => {
          console.log('Logging out...');
        },
      }
    ],
  }

}
