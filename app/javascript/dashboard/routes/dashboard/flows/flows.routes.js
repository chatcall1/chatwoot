import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import FlowBuilderIndex from './Index.vue';
import SettingsContent from '../settings/Wrapper.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/flows'),
    component: SettingsContent,
    props: {
      headerTitle: 'FLOW_BUILDER.TITLE',
      icon: 'flow',
      keepAlive: false,
    },
    children: [
      {
        path: '',
        name: 'flows_index',
        component: FlowBuilderIndex,
        meta: {
          featureFlag: FEATURE_FLAGS.FLOW_BUILDER,
          permissions: ['administrator'],
        },
      },
    ],
  },
];
