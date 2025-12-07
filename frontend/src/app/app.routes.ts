import { Routes } from '@angular/router';

export const routes: Routes = [
    {
      path: '',
      redirectTo: 'documents',
      pathMatch: 'full',
    },
    {
      path: 'dashboard',
      loadComponent: () => import('../app/components/dashboard/dashboard').then(m => m.Dashboard),
    },
    {
      path: 'documents',
      loadComponent: () => import('../app/components/documents/documents').then(m => m.Documents),
    }
];
