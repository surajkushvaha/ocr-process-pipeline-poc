import { Component } from '@angular/core';
import { HlmBreadCrumbImports } from '@spartan-ng/helm/breadcrumb';
import { HlmDropdownMenuImports } from '@spartan-ng/helm/dropdown-menu';
import { HlmIcon } from "@spartan-ng/helm/icon";
import { HlmButton, HlmButtonImports } from "@spartan-ng/helm/button";
import { NgIcon, provideIcons } from '@ng-icons/core';
import { lucideFile, lucidePlus } from '@ng-icons/lucide';
import { BrnDialogImports } from '@spartan-ng/brain/dialog';
import { HlmDialogImports } from '@spartan-ng/helm/dialog';
import { HlmInputImports } from '@spartan-ng/helm/input';
import { HlmLabelImports } from '@spartan-ng/helm/label';
import { HlmEmptyImports } from '@spartan-ng/helm/empty';

@Component({
  selector: 'app-listing',
	imports: [
    HlmBreadCrumbImports, HlmDropdownMenuImports, HlmIcon, HlmButton,NgIcon,
    BrnDialogImports, HlmDialogImports, HlmLabelImports, HlmInputImports, HlmButtonImports,HlmEmptyImports
  ],
  templateUrl: './listing.html',
  styleUrl: './listing.scss',
  providers: [
    provideIcons({
      lucideFile, lucidePlus
    })
  ]
})
export class Listing {
  openModal() {

  }

  onChangeFile(event: Event) {}
}

