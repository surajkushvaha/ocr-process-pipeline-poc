import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { provideIcons } from '@ng-icons/core';
import { lucidePanelLeft } from '@ng-icons/lucide';
import { HlmButton, provideBrnButtonConfig } from '@spartan-ng/helm/button';
import { HlmIconImports } from '@spartan-ng/helm/icon';
import { HlmSidebarService } from './hlm-sidebar.service';

@Component({
	// eslint-disable-next-line @angular-eslint/component-selector
	selector: 'button[hlmSidebarTrigger]',
	imports: [HlmIconImports],
	providers: [provideIcons({ lucidePanelLeft }), provideBrnButtonConfig({ variant: 'ghost', size: 'icon' })],
	changeDetection: ChangeDetectionStrategy.OnPush,
	hostDirectives: [
		{
			directive: HlmButton,
		},
	],
	host: {
		'data-slot': 'sidebar-trigger',
		'data-sidebar': 'trigger',
		'(click)': '_onClick()',
	},
	template: `
    <ng-content select="[hlm]"></ng-content>
	`,
})
export class HlmSidebarTrigger {
	private readonly _hlmBtn = inject(HlmButton);
	private readonly _sidebarService = inject(HlmSidebarService);

	constructor() {
		this._hlmBtn.setClass('size-7');
	}

	protected _onClick(): void {
		this._sidebarService.toggleSidebar();
	}
}
