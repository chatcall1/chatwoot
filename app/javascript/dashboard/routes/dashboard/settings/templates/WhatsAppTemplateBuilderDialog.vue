<script setup>
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';

import InboxesAPI from 'dashboard/api/inboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { useAlert } from 'dashboard/composables';
import AuthenticationTemplateEditor from './components/AuthenticationTemplateEditor.vue';
import CatalogTemplateEditor from './components/CatalogTemplateEditor.vue';
import CarouselTemplateEditor from './components/CarouselTemplateEditor.vue';
import TemplateBasicsStep from './components/TemplateBasicsStep.vue';
import WhatsAppTemplatePhonePreview from './components/WhatsAppTemplatePhonePreview.vue';
import StandardTemplateEditor from './components/StandardTemplateEditor.vue';

const props = defineProps({
  inboxes: { type: Array, default: () => [] },
});
const emit = defineEmits(['close', 'submitted']);
const { t } = useI18n();
const dialogRef = ref(null);
const step = ref(1);
const selectedSection = ref('body');
const templateFormat = ref('standard');
const catalogFormat = ref('catalog_template');
const productTemplateType = ref('spm');
const productCarouselButtonType = ref('SPM');
const productCarouselUrl = reactive({ text: '', url: '', example: '' });
const selectedCatalogId = ref('');
const catalogs = ref([]);
const isLoadingCatalogs = ref(false);
const hasFetchedCatalogs = ref(false);
const flows = ref([]);
const isLoadingFlows = ref(false);
const authenticationMetaPreview = ref(null);
let authenticationPreviewRequestId = 0;
const activeCardIndex = ref(0);
let nextAuthenticationAppId = 1;
const createAuthenticationApp = () => {
  const app = {
    id: nextAuthenticationAppId,
    packageName: '',
    signatureHash: '',
  };
  nextAuthenticationAppId += 1;
  return app;
};
const carouselEditorCardElements = new Map();
const carouselPreviewCardElements = new Map();
const isSubmitting = ref(false);
let nextCarouselCardId = 1;
const generateCarouselCardId = () => {
  const id = nextCarouselCardId;
  nextCarouselCardId += 1;
  return id;
};
let nextStandardButtonId = 1;
const createStandardButton = () => {
  const button = {
    id: nextStandardButtonId,
    type: 'QUICK_REPLY',
    text: '',
    value: '',
    example: '',
    flowId: '',
    deepLinkEnabled: false,
    metaAppId: '',
    androidDeepLink: '',
    androidFallbackUrl: '',
  };
  nextStandardButtonId += 1;
  return button;
};
const createCarouselCard = () => ({
  id: generateCarouselCardId(),
  body: '',
  bodyExamples: {},
  mediaUrl: '',
  mediaName: '',
  mediaMimeType: '',
  mediaFile: null,
  buttons: {
    QUICK_REPLY: { text: '', value: '', example: '' },
    URL: { text: '', value: '', example: '' },
    PHONE_NUMBER: { text: '', value: '', example: '' },
  },
});

const state = reactive({
  inboxId: '',
  category: '',
  name: '',
  language: 'ar',
  headerType: 'none',
  headerText: '',
  headerMediaUrl: '',
  headerMediaName: '',
  headerMediaFile: null,
  headerExample: '',
  headerGifEnabled: false,
  body: '',
  bodyExamples: {},
  footer: '',
  buttonText: '',
  buttonType: 'QUICK_REPLY',
  flowId: '',
  standardButtons: [],
  authenticationOtpType: 'COPY_CODE',
  authenticationSecurityRecommendation: true,
  authenticationExpirationEnabled: true,
  authenticationCodeExpirationMinutes: 10,
  authenticationTtlEnabled: false,
  authenticationTtlSeconds: 60,
  authenticationCopyCodeText: '',
  authenticationAutofillText: '',
  authenticationTermsAccepted: false,
  authenticationApps: [createAuthenticationApp()],
  carouselMediaType: 'image',
  carouselTextEnabled: true,
  carouselButtonTypes: [],
  cards: [createCarouselCard(), createCarouselCard()],
});

const createFormatDraft = () => ({
  headerType: 'none',
  headerText: '',
  headerMediaUrl: '',
  headerMediaName: '',
  headerMediaFile: null,
  headerExample: '',
  headerGifEnabled: false,
  body: '',
  bodyExamples: {},
  footer: '',
  buttonText: '',
  buttonType: 'QUICK_REPLY',
  flowId: '',
  standardButtons: [],
});
const formatDrafts = reactive({
  standard: createFormatDraft(),
  carousel: createFormatDraft(),
  catalog: createFormatDraft(),
});
const catalogDrafts = reactive({
  catalog_template: createFormatDraft(),
  product_carousel: createFormatDraft(),
  spm: createFormatDraft(),
  mpm: createFormatDraft(),
});
const currentFormatDraft = () => ({
  headerType: state.headerType,
  headerText: state.headerText,
  headerMediaUrl: state.headerMediaUrl,
  headerMediaName: state.headerMediaName,
  headerMediaFile: state.headerMediaFile,
  headerExample: state.headerExample,
  headerGifEnabled: state.headerGifEnabled,
  body: state.body,
  bodyExamples: { ...state.bodyExamples },
  footer: state.footer,
  buttonText: state.buttonText,
  buttonType: state.buttonType,
  flowId: state.flowId,
  standardButtons: state.standardButtons.map(button => ({ ...button })),
});
const saveFormatDraft = format => {
  formatDrafts[format] = currentFormatDraft();
};
const restoreDraft = draft => {
  Object.assign(state, {
    ...draft,
    bodyExamples: { ...draft.bodyExamples },
    standardButtons: draft.standardButtons.map(button => ({ ...button })),
  });
};
const restoreFormatDraft = format => restoreDraft(formatDrafts[format]);
const catalogDraftKey = (format, productType) =>
  format === 'products' ? productType : format;

const categories = computed(() => [
  {
    value: 'UTILITY',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATEGORIES.UTILITY'),
    description: t('WHATSAPP_TEMPLATE_BUILDER.CATEGORY_DESCRIPTIONS.UTILITY'),
    icon: 'i-lucide-bell-ring',
  },
  {
    value: 'MARKETING',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATEGORIES.MARKETING'),
    description: t('WHATSAPP_TEMPLATE_BUILDER.CATEGORY_DESCRIPTIONS.MARKETING'),
    icon: 'i-lucide-megaphone',
  },
  {
    value: 'AUTHENTICATION',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATEGORIES.AUTHENTICATION'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATEGORY_DESCRIPTIONS.AUTHENTICATION'
    ),
    icon: 'i-lucide-shield-check',
  },
]);
const languages = computed(() => [
  { value: 'ar', label: t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGES.ARABIC') },
  { value: 'en_US', label: t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGES.ENGLISH') },
]);
const authenticationOtpTypes = computed(() => [
  {
    value: 'COPY_CODE',
    label: t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.COPY_CODE'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.COPY_CODE_DESCRIPTION'
    ),
    icon: 'i-lucide-copy',
  },
  {
    value: 'ONE_TAP',
    label: t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.ONE_TAP'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.ONE_TAP_DESCRIPTION'
    ),
    icon: 'i-lucide-smartphone',
  },
  {
    value: 'ZERO_TAP',
    label: t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.ZERO_TAP'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TYPES.ZERO_TAP_DESCRIPTION'
    ),
    icon: 'i-lucide-zap',
  },
]);
const inboxOptions = computed(() =>
  props.inboxes.map(inbox => ({ value: String(inbox.id), label: inbox.name }))
);
const headerTypes = computed(() => [
  { value: 'none', label: t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.NONE') },
  { value: 'text', label: t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.TEXT') },
  { value: 'image', label: t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.IMAGE') },
  { value: 'video', label: t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.VIDEO') },
  {
    value: 'document',
    label: t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.DOCUMENT'),
  },
]);
const mediaHeaderTypes = computed(() =>
  headerTypes.value.filter(option => {
    if (
      templateFormat.value === 'catalog' &&
      catalogFormat.value === 'products' &&
      productTemplateType.value === 'mpm'
    ) {
      return option.value === 'text';
    }
    return option.value !== 'none';
  })
);
const templateFormats = computed(() => [
  {
    value: 'standard',
    label: t('WHATSAPP_TEMPLATE_BUILDER.FORMATS.STANDARD'),
    icon: 'i-lucide-layout-template',
  },
  {
    value: 'carousel',
    label: t('WHATSAPP_TEMPLATE_BUILDER.FORMATS.CAROUSEL'),
    icon: 'i-lucide-panels-top-left',
  },
  {
    value: 'catalog',
    label: t('WHATSAPP_TEMPLATE_BUILDER.FORMATS.CATALOG'),
    icon: 'i-lucide-shopping-bag',
  },
]);
const catalogFormats = computed(() => [
  {
    value: 'catalog_template',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.CATALOG'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.CATALOG_DESCRIPTION'
    ),
    icon: 'i-lucide-store',
  },
  {
    value: 'product_carousel',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.CAROUSEL'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.CAROUSEL_DESCRIPTION'
    ),
    icon: 'i-lucide-panels-top-left',
  },
  {
    value: 'products',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.PRODUCTS'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATALOG.FORMATS.PRODUCTS_DESCRIPTION'
    ),
    icon: 'i-lucide-shopping-bag',
  },
]);
const productTemplateTypes = computed(() => [
  {
    value: 'spm',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_TYPES.SINGLE'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_TYPES.SINGLE_DESCRIPTION'
    ),
    icon: 'i-lucide-package',
  },
  {
    value: 'mpm',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_TYPES.MULTI'),
    description: t(
      'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_TYPES.MULTI_DESCRIPTION'
    ),
    icon: 'i-lucide-package-open',
  },
]);
const productCarouselButtonTypes = computed(() => [
  {
    value: 'SPM',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.SPM'),
  },
  {
    value: 'URL',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL'),
  },
]);
const catalogOptions = computed(() =>
  catalogs.value.map(catalog => ({
    value: String(catalog.id),
    label: catalog.name || catalog.id,
  }))
);
const flowOptions = computed(() =>
  flows.value.map(flow => ({ value: String(flow.id), label: flow.name }))
);
const fetchCatalogs = async () => {
  if (!state.inboxId) return;
  isLoadingCatalogs.value = true;
  hasFetchedCatalogs.value = false;
  try {
    const { data } = await InboxesAPI.getProductCatalogs(state.inboxId);
    catalogs.value = data.payload || [];
    if (
      !catalogOptions.value.some(
        option => option.value === selectedCatalogId.value
      )
    ) {
      selectedCatalogId.value = catalogOptions.value[0]?.value || '';
    }
  } catch {
    catalogs.value = [];
    selectedCatalogId.value = '';
  } finally {
    isLoadingCatalogs.value = false;
    hasFetchedCatalogs.value = true;
  }
};
const fetchFlows = async () => {
  if (!state.inboxId) return;
  isLoadingFlows.value = true;
  try {
    const { data } = await InboxesAPI.getWhatsappFlows(state.inboxId);
    flows.value = data.payload || [];
    if (!flowOptions.value.some(option => option.value === state.flowId)) {
      state.flowId = '';
    }
  } finally {
    isLoadingFlows.value = false;
  }
};
const fetchAuthenticationPreview = useDebounceFn(async () => {
  if (
    step.value !== 2 ||
    state.category !== 'AUTHENTICATION' ||
    !state.inboxId
  ) {
    return;
  }

  authenticationPreviewRequestId += 1;
  const requestId = authenticationPreviewRequestId;
  try {
    const { data } = await InboxesAPI.getAuthenticationTemplatePreview(
      state.inboxId,
      {
        language: state.language,
        add_security_recommendation: state.authenticationSecurityRecommendation,
        code_expiration_minutes: state.authenticationExpirationEnabled
          ? state.authenticationCodeExpirationMinutes
          : undefined,
      }
    );
    if (requestId === authenticationPreviewRequestId) {
      authenticationMetaPreview.value = data.payload || null;
    }
  } catch {
    if (requestId === authenticationPreviewRequestId) {
      authenticationMetaPreview.value = null;
    }
  }
}, 400);
const buttonTypes = computed(() => [
  {
    value: 'QUICK_REPLY',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.QUICK_REPLY'),
  },
  { value: 'URL', label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.URL') },
  {
    value: 'PHONE_NUMBER',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.PHONE_NUMBER'),
  },
  {
    value: 'FLOW',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.FLOW'),
  },
  {
    value: 'COPY_CODE',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.COPY_CODE'),
  },
]);
const addStandardButton = () => {
  if (state.standardButtons.length < 10) {
    state.standardButtons.push(createStandardButton());
  }
};
const removeStandardButton = index => state.standardButtons.splice(index, 1);
const carouselActionTypes = computed(() => [
  {
    value: 'QUICK_REPLY',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.QUICK_REPLY'),
    icon: 'i-lucide-reply',
    valueLabel: '',
    valuePlaceholder: '',
  },
  {
    value: 'URL',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL'),
    icon: 'i-lucide-external-link',
    valueLabel: t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_VALUE'),
    valuePlaceholder: t(
      'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_PLACEHOLDER'
    ),
  },
  {
    value: 'PHONE_NUMBER',
    label: t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE'),
    icon: 'i-lucide-phone',
    valueLabel: t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE_VALUE'),
    valuePlaceholder: t(
      'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE_PLACEHOLDER'
    ),
  },
]);
const carouselActionByValue = computed(() =>
  Object.fromEntries(
    carouselActionTypes.value.map(action => [action.value, action])
  )
);
const activeCard = computed(() => state.cards[activeCardIndex.value]);
const selectCarouselCard = index => {
  activeCardIndex.value = index;
};
const isValidPhoneNumber = value => /^[+\d][\d\s().-]{5,19}$/.test(value);
const POSITIONAL_VARIABLE_PATTERN = /\{\{(\d+)\}\}/g;
const variablePattern = () => POSITIONAL_VARIABLE_PATTERN;
const isValidTemplateText = (
  value,
  { maxLineBreaks, allowVariableAtEnd = false } = {}
) => {
  const text = value.trim();
  const variableIndexes = [...text.matchAll(variablePattern())].map(match =>
    Number(match[1])
  );
  const uniqueIndexes = [...new Set(variableIndexes)];
  const hasInvalidVariable = /\{\{|\}\}/.test(
    text.replace(variablePattern(), '')
  );
  const hasSequentialVariables = uniqueIndexes.every(
    (index, position) => index === position + 1
  );
  const boundaryPattern = '\\d+';
  const hasInvalidVariableBoundary =
    new RegExp(`^\\s*\\{\\{${boundaryPattern}\\}\\}`).test(text) ||
    (!allowVariableAtEnd &&
      new RegExp(`\\{\\{${boundaryPattern}\\}\\}\\s*$`).test(text));
  const hasAdjacentVariables = /\}\}\s*\{\{/.test(text);
  const hasValidLineBreaks =
    maxLineBreaks === undefined || text.split('\n').length - 1 <= maxLineBreaks;

  return (
    !hasInvalidVariable &&
    hasSequentialVariables &&
    !hasInvalidVariableBoundary &&
    !hasAdjacentVariables &&
    hasValidLineBreaks
  );
};
const variableIndexes = value => [
  ...new Set(
    [...value.matchAll(variablePattern())].map(match => Number(match[1]))
  ),
];
const bodyVariableIndexes = computed(() => variableIndexes(state.body));
const activeCardVariableIndexes = computed(() =>
  variableIndexes(activeCard.value.body)
);
const hasCompleteExamples = (indexes, examples) =>
  indexes.every(index => !!examples[index]?.trim());
const buildExamples = (text, examples) => {
  const keys = variableIndexes(text);
  return keys.map(key => examples[key]);
};
const emptyExamples = () => [];
const isValidUrl = value => {
  try {
    const variables = [...value.matchAll(variablePattern())];
    const placeholder = variables.length ? `{{${variables[0][1]}}}` : '';
    if (
      variables.length > 1 ||
      (variables.length === 1 && !value.endsWith(placeholder))
    ) {
      return false;
    }
    const url = new URL(value.replace(variablePattern(), 'example'));
    return (
      isValidTemplateText(value, { allowVariableAtEnd: true }) &&
      ['http:', 'https:'].includes(url.protocol) &&
      !!url.hostname
    );
  } catch {
    return false;
  }
};
const isValidButton = (button, type) => {
  const hasValidText = !!button.text.trim() && button.text.trim().length <= 25;
  if (!hasValidText) return false;
  if (type === 'URL') {
    const hasVariable = variableIndexes(button.value).length > 0;
    return (
      isValidUrl(button.value) && (!hasVariable || !!button.example.trim())
    );
  }
  if (type === 'PHONE_NUMBER') return isValidPhoneNumber(button.value);
  return true;
};
const hasValidQuickReplyGrouping = buttons => {
  const groups = buttons.reduce((result, button) => {
    const isQuickReply = button.type === 'QUICK_REPLY';
    if (result.at(-1) !== isQuickReply) result.push(isQuickReply);
    return result;
  }, []);
  return groups.filter(Boolean).length <= 1;
};
const isCardComplete = card =>
  !!card.mediaFile &&
  (!state.carouselTextEnabled ||
    (!!card.body.trim() &&
      card.body.length <= 160 &&
      isValidTemplateText(card.body, { maxLineBreaks: 2 }) &&
      hasCompleteExamples(variableIndexes(card.body), card.bodyExamples))) &&
  state.carouselButtonTypes.every(action =>
    isValidButton(card.buttons[action], action)
  );
const nameError = computed(() =>
  state.name && (!/^[a-z0-9_]+$/.test(state.name) || state.name.length > 512)
    ? t('WHATSAPP_TEMPLATE_BUILDER.NAME.ERROR')
    : ''
);
const canContinue = computed(
  () =>
    !!state.inboxId &&
    !!state.category &&
    !!state.name &&
    !nameError.value &&
    !!state.language
);
const isCarouselValid = computed(
  () =>
    state.category === 'MARKETING' &&
    templateFormat.value === 'carousel' &&
    !!state.body.trim() &&
    state.body.length <= 1024 &&
    isValidTemplateText(state.body) &&
    hasCompleteExamples(bodyVariableIndexes.value, state.bodyExamples) &&
    state.cards.length >= 2 &&
    state.cards.every(isCardComplete)
);
const catalogBodyMaxLength = computed(() =>
  catalogFormat.value === 'products' && productTemplateType.value === 'spm'
    ? 160
    : 1024
);
const isCatalogValid = computed(
  () =>
    templateFormat.value === 'catalog' &&
    !!selectedCatalogId.value &&
    !!state.body.trim() &&
    state.body.length <= catalogBodyMaxLength.value &&
    isValidTemplateText(state.body) &&
    hasCompleteExamples(bodyVariableIndexes.value, state.bodyExamples) &&
    (catalogFormat.value !== 'products' ||
      productTemplateType.value !== 'mpm' ||
      (!!state.headerText.trim() &&
        (!variableIndexes(state.headerText).length ||
          !!state.headerExample.trim()))) &&
    (catalogFormat.value !== 'product_carousel' ||
      productCarouselButtonType.value === 'SPM' ||
      (!!productCarouselUrl.text.trim() &&
        productCarouselUrl.text.trim().length <= 25 &&
        isValidUrl(productCarouselUrl.url) &&
        (!variableIndexes(productCarouselUrl.url).length ||
          !!productCarouselUrl.example.trim())))
);
const isAuthenticationAppValid = app =>
  /^(?:[A-Za-z][A-Za-z0-9_]*\.)+[A-Za-z][A-Za-z0-9_]*$/.test(app.packageName) &&
  /^[A-Za-z0-9+/=]{11}$/.test(app.signatureHash);
const isAuthenticationValid = computed(() => {
  if (state.category !== 'AUTHENTICATION') return false;
  if (
    state.authenticationExpirationEnabled &&
    (!Number.isInteger(Number(state.authenticationCodeExpirationMinutes)) ||
      Number(state.authenticationCodeExpirationMinutes) < 1 ||
      Number(state.authenticationCodeExpirationMinutes) > 90)
  ) {
    return false;
  }
  if (
    state.authenticationTtlEnabled &&
    (!Number.isInteger(Number(state.authenticationTtlSeconds)) ||
      Number(state.authenticationTtlSeconds) < 30 ||
      Number(state.authenticationTtlSeconds) > 900)
  ) {
    return false;
  }
  if (
    ['ONE_TAP', 'ZERO_TAP'].includes(state.authenticationOtpType) &&
    !state.authenticationApps.every(isAuthenticationAppValid)
  ) {
    return false;
  }
  return (
    state.authenticationOtpType !== 'ZERO_TAP' ||
    state.authenticationTermsAccepted
  );
});
const isStandardValid = computed(
  () =>
    ['MARKETING', 'UTILITY'].includes(state.category) &&
    templateFormat.value === 'standard' &&
    hasValidQuickReplyGrouping(state.standardButtons) &&
    state.standardButtons.every(button => {
      if (button.type === 'COPY_CODE') {
        return !!button.example.trim() && button.example.trim().length <= 20;
      }
      if (!button.text.trim() || button.text.trim().length > 25) return false;
      if (button.type === 'FLOW') return !!button.flowId;
      if (button.type === 'URL') {
        return (
          isValidUrl(button.value) &&
          (!variableIndexes(button.value).length || !!button.example.trim()) &&
          (!button.deepLinkEnabled ||
            (/^\d+$/.test(button.metaAppId) &&
              /^[a-z][a-z0-9+.-]*:\/\//i.test(button.androidDeepLink) &&
              isValidUrl(button.androidFallbackUrl)))
        );
      }
      if (button.type === 'PHONE_NUMBER') {
        return isValidPhoneNumber(button.value);
      }
      return true;
    }) &&
    (state.headerType !== 'text' ||
      (!!state.headerText.trim() &&
        (!variableIndexes(state.headerText).length ||
          !!state.headerExample.trim()))) &&
    (!['image', 'video', 'document'].includes(state.headerType) ||
      !!state.headerMediaFile) &&
    !!state.body.trim() &&
    state.body.length <= 1024 &&
    isValidTemplateText(state.body) &&
    hasCompleteExamples(bodyVariableIndexes.value, state.bodyExamples)
);
const isTemplateValid = computed(
  () =>
    isAuthenticationValid.value ||
    isStandardValid.value ||
    isCarouselValid.value ||
    isCatalogValid.value
);
const direction = computed(() => (state.language === 'ar' ? 'rtl' : 'ltr'));
const authenticationPreview = computed(() => {
  const minutes = { minutes: state.authenticationCodeExpirationMinutes };
  return state.language === 'ar'
    ? {
        body: t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ARABIC.BODY'),
        security: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ARABIC.SECURITY'
        ),
        expiration: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ARABIC.EXPIRATION',
          minutes
        ),
        copy: t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ARABIC.COPY'),
        autofill: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ARABIC.AUTOFILL'
        ),
      }
    : {
        body: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ENGLISH.BODY'
        ),
        security: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ENGLISH.SECURITY'
        ),
        expiration: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ENGLISH.EXPIRATION',
          minutes
        ),
        copy: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ENGLISH.COPY'
        ),
        autofill: t(
          'WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.ENGLISH.AUTOFILL'
        ),
      };
});
const authenticationPreviewBody = computed(() => {
  const code = t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PREVIEW.CODE');
  const metaBody = authenticationMetaPreview.value?.body;
  if (metaBody) return metaBody.replace(/\*?\{\{1\}\}\*?/, code);

  const security = state.authenticationSecurityRecommendation
    ? ` ${authenticationPreview.value.security}`
    : '';
  return `${code} ${authenticationPreview.value.body}${security}`;
});
const authenticationPreviewButton = computed(() => {
  const metaButton = authenticationMetaPreview.value?.buttons?.[0];
  if (state.authenticationOtpType === 'COPY_CODE') {
    return (
      state.authenticationCopyCodeText ||
      metaButton?.text ||
      authenticationPreview.value.copy
    );
  }
  return (
    state.authenticationAutofillText ||
    metaButton?.autofill_text ||
    authenticationPreview.value.autofill
  );
});
const authenticationPreviewFooter = computed(
  () =>
    authenticationMetaPreview.value?.footer ||
    authenticationPreview.value.expiration
);

const sections = computed(() => [
  {
    key: 'header',
    label: t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.HEADER'),
    optional: true,
  },
  {
    key: 'body',
    label: t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.BODY'),
    optional: false,
  },
  {
    key: 'footer',
    label: t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.FOOTER'),
    optional: true,
  },
  {
    key: 'buttons',
    label: t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.BUTTONS'),
    optional: true,
  },
]);
const visibleSections = computed(() =>
  templateFormat.value === 'catalog'
    ? sections.value.filter(section => {
        if (section.key === 'buttons') return false;
        if (section.key !== 'header') return true;
        return (
          catalogFormat.value === 'products' &&
          productTemplateType.value === 'mpm'
        );
      })
    : sections.value
);

const open = () => dialogRef.value?.open();
const releasePreviewUrls = () => {
  const previewUrls = new Set(
    [state.headerMediaUrl, ...state.cards.map(card => card.mediaUrl)].filter(
      Boolean
    )
  );
  previewUrls.forEach(url => URL.revokeObjectURL(url));
};
const close = () => {
  dialogRef.value?.close();
};
const handleDialogClose = () => {
  releasePreviewUrls();
  emit('close');
};
const continueToBuilder = () => {
  if (canContinue.value) step.value = 2;
};
const toggleSection = key => {
  selectedSection.value = selectedSection.value === key ? '' : key;
};
const toggleHeaderType = headerType => {
  state.headerType = state.headerType === headerType ? 'none' : headerType;
  if (state.headerType !== 'video') state.headerGifEnabled = false;
};
const setHeaderGifMode = enabled => {
  state.headerGifEnabled = enabled;
  if (state.headerMediaUrl) URL.revokeObjectURL(state.headerMediaUrl);
  state.headerMediaUrl = '';
  state.headerMediaName = '';
  state.headerMediaFile = null;
};
const addAuthenticationApp = () => {
  state.authenticationApps.push(createAuthenticationApp());
};
const removeAuthenticationApp = index => {
  if (state.authenticationApps.length > 1) {
    state.authenticationApps.splice(index, 1);
  }
};
const mediaAccept = computed(() => {
  if (state.headerType === 'video') {
    if (state.headerGifEnabled) return 'video/mp4';
    return 'video/mp4,video/3gpp';
  }
  if (state.headerType === 'document') return 'application/pdf';
  return 'image/jpeg,image/png';
});
const handleHeaderFile = file => {
  if (!file?.file) return;
  const limits = {
    image: { types: ['image/jpeg', 'image/png'], size: 5 * 1024 * 1024 },
    video: { types: ['video/mp4', 'video/3gpp'], size: 16 * 1024 * 1024 },
    gif: { types: ['video/mp4'], size: 3.5 * 1024 * 1024 },
    document: { types: ['application/pdf'], size: 100 * 1024 * 1024 },
  };
  const rules =
    limits[
      state.headerType === 'video' && state.headerGifEnabled
        ? 'gif'
        : state.headerType
    ];
  if (!rules?.types.includes(file.type) || file.size > rules.size) {
    useAlert(t('WHATSAPP_TEMPLATE_BUILDER.HEADER.MEDIA_ERROR'));
    return;
  }
  if (state.headerMediaUrl) URL.revokeObjectURL(state.headerMediaUrl);
  state.headerMediaUrl = URL.createObjectURL(file.file);
  state.headerMediaName = file.name;
  state.headerMediaFile = file.file;
};
const handleCardFile = (file, index) => {
  if (!file?.file) return;
  const isVideo = state.carouselMediaType === 'video';
  const allowedTypes = isVideo
    ? ['video/mp4', 'video/3gpp']
    : ['image/jpeg', 'image/png'];
  const maxSize = (isVideo ? 16 : 5) * 1024 * 1024;
  if (!allowedTypes.includes(file.type) || file.size > maxSize) {
    useAlert(t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.MEDIA_ERROR'));
    return;
  }
  const card = state.cards[index];
  if (
    card.mediaUrl &&
    !state.cards.some(
      (otherCard, cardIndex) =>
        cardIndex !== index && otherCard.mediaUrl === card.mediaUrl
    )
  ) {
    URL.revokeObjectURL(card.mediaUrl);
  }
  card.mediaUrl = URL.createObjectURL(file.file);
  card.mediaName = file.name;
  card.mediaMimeType = file.type;
  card.mediaFile = file.file;
};
const addCard = () => {
  if (state.cards.length >= 10) return;
  state.cards.push(createCarouselCard());
  activeCardIndex.value = state.cards.length - 1;
};
const duplicateCard = () => {
  if (state.cards.length >= 10) return;
  const source = activeCard.value;
  state.cards.splice(activeCardIndex.value + 1, 0, {
    ...source,
    id: generateCarouselCardId(),
    bodyExamples: { ...source.bodyExamples },
    buttons: Object.fromEntries(
      Object.entries(source.buttons).map(([key, value]) => [key, { ...value }])
    ),
  });
  activeCardIndex.value += 1;
};
const deleteCard = () => {
  if (state.cards.length <= 2) return;
  const [deletedCard] = state.cards.splice(activeCardIndex.value, 1);
  if (
    deletedCard.mediaUrl &&
    !state.cards.some(card => card.mediaUrl === deletedCard.mediaUrl)
  ) {
    URL.revokeObjectURL(deletedCard.mediaUrl);
  }
  activeCardIndex.value = Math.min(
    activeCardIndex.value,
    state.cards.length - 1
  );
};
const navigateCard = offset => {
  activeCardIndex.value = Math.min(
    Math.max(activeCardIndex.value + offset, 0),
    state.cards.length - 1
  );
};
const setCarouselEditorCardElement = (cardId, element) => {
  if (element) carouselEditorCardElements.set(cardId, element);
  else carouselEditorCardElements.delete(cardId);
};
const setCarouselPreviewCardElement = (cardId, element) => {
  if (element) carouselPreviewCardElements.set(cardId, element);
  else carouselPreviewCardElements.delete(cardId);
};
const scrollToActiveCard = () => {
  nextTick(() => {
    const cardId = activeCard.value?.id;
    [carouselEditorCardElements, carouselPreviewCardElements].forEach(
      cardElements => {
        cardElements.get(cardId)?.scrollIntoView({
          behavior: 'smooth',
          block: 'nearest',
          inline: 'center',
        });
      }
    );
  });
};
const toggleCarouselAction = action => {
  const index = state.carouselButtonTypes.indexOf(action);
  if (index >= 0) {
    state.carouselButtonTypes.splice(index, 1);
    return;
  }
  if (state.carouselButtonTypes.length < 2) {
    state.carouselButtonTypes.push(action);
  }
};
const carouselMediaAccept = computed(() =>
  state.carouselMediaType === 'video'
    ? 'video/mp4,video/3gpp'
    : 'image/jpeg,image/png'
);
const setCarouselMediaType = type => {
  if (state.carouselMediaType === type) return;
  state.cards.forEach(card => {
    if (card.mediaUrl) URL.revokeObjectURL(card.mediaUrl);
    card.mediaUrl = '';
    card.mediaName = '';
    card.mediaMimeType = '';
    card.mediaFile = null;
  });
  state.carouselMediaType = type;
};
const addBodyVariable = () => {
  const name = bodyVariableIndexes.value.length + 1;
  state.body = `${state.body}${state.body ? ' ' : ''}{{${name}}}`;
};
const addHeaderVariable = () => {
  if (variableIndexes(state.headerText).length) return;
  state.headerText = `${state.headerText}${state.headerText ? ' ' : ''}{{1}}`;
};
const addCardVariable = () => {
  const variables = variableIndexes(activeCard.value.body);
  const name = variables.length + 1;
  activeCard.value.body = `${activeCard.value.body}${
    activeCard.value.body ? ' ' : ''
  }{{${name}}}`;
};
const carouselActionError = action => {
  const button = activeCard.value.buttons[action];
  if (!button.text.trim()) return '';
  if (button.text.trim().length > 25) {
    return t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.TEXT_ERROR');
  }
  if (action === 'URL' && button.value && !isValidUrl(button.value)) {
    return t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_ERROR');
  }
  if (
    action === 'PHONE_NUMBER' &&
    button.value &&
    !isValidPhoneNumber(button.value)
  ) {
    return t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE_ERROR');
  }
  return '';
};
const normalizePhoneNumber = event => {
  activeCard.value.buttons.PHONE_NUMBER.value = event.target.value.replace(
    /(?!^\+)\D/g,
    ''
  );
};
const submitCarouselTemplate = async () => {
  if (!isTemplateValid.value || isSubmitting.value) return;

  isSubmitting.value = true;
  const formData = new FormData();
  const template = {
    name: state.name,
    language: state.language,
    category: state.category,
    parameter_format: 'POSITIONAL',
    body: state.body,
    media_type: state.carouselMediaType.toUpperCase(),
    card_text_enabled: state.carouselTextEnabled,
    button_types: state.carouselButtonTypes,
    cards: state.cards.map(card => ({
      body: state.carouselTextEnabled ? card.body : '',
      body_examples: state.carouselTextEnabled
        ? buildExamples(card.body, card.bodyExamples)
        : emptyExamples(),
      buttons: card.buttons,
    })),
    body_examples: buildExamples(state.body, state.bodyExamples),
  };
  if (state.category === 'AUTHENTICATION') {
    delete template.parameter_format;
    delete template.media_type;
    delete template.card_text_enabled;
    delete template.button_types;
    delete template.cards;
    delete template.body;
    delete template.body_examples;
    template.authentication = {
      otp_type: state.authenticationOtpType,
      add_security_recommendation: state.authenticationSecurityRecommendation,
      code_expiration_minutes: state.authenticationExpirationEnabled
        ? Number(state.authenticationCodeExpirationMinutes)
        : null,
      message_send_ttl_seconds: state.authenticationTtlEnabled
        ? Number(state.authenticationTtlSeconds)
        : null,
      copy_code_text: state.authenticationCopyCodeText.trim(),
      autofill_text: state.authenticationAutofillText.trim(),
      zero_tap_terms_accepted: state.authenticationTermsAccepted,
      supported_apps: state.authenticationApps.map(app => ({
        package_name: app.packageName.trim(),
        signature_hash: app.signatureHash.trim(),
      })),
    };
  } else if (templateFormat.value === 'standard') {
    delete template.media_type;
    delete template.card_text_enabled;
    delete template.button_types;
    delete template.cards;
    template.template_format = 'standard';
    template.header_type = state.headerGifEnabled ? 'gif' : state.headerType;
    template.header_text = state.headerText;
    template.header_example = state.headerExample;
    template.footer = state.footer;
    template.buttons = state.standardButtons.map(button => ({
      type: button.type,
      text: button.text.trim(),
      value: button.value.trim(),
      example: button.example.trim(),
      flow_id: button.flowId,
      app_deep_link: button.deepLinkEnabled
        ? {
            meta_app_id: button.metaAppId,
            android_deep_link: button.androidDeepLink.trim(),
            android_fallback_playstore_url: button.androidFallbackUrl.trim(),
          }
        : null,
    }));
  } else if (templateFormat.value === 'catalog') {
    delete template.media_type;
    delete template.card_text_enabled;
    delete template.button_types;
    delete template.cards;
    template.catalog_format = catalogFormat.value;
    template.catalog_id = selectedCatalogId.value;
    template.product_template_type = productTemplateType.value;
    template.product_carousel_button_type = productCarouselButtonType.value;
    template.product_carousel_button = { ...productCarouselUrl };
    if (
      catalogFormat.value === 'products' &&
      productTemplateType.value === 'mpm'
    ) {
      template.header_text = state.headerText;
      template.header_example = state.headerExample;
    }
  }
  formData.append('template', JSON.stringify(template));
  if (templateFormat.value === 'carousel') {
    state.cards.forEach((card, index) => {
      formData.append(`media_${index}`, card.mediaFile);
    });
  }
  if (
    templateFormat.value === 'standard' &&
    ['image', 'video', 'document'].includes(state.headerType)
  ) {
    formData.append('header_media', state.headerMediaFile);
  }

  try {
    const { data } = await InboxesAPI.createMessageTemplate(
      state.inboxId,
      formData
    );
    useAlert(
      data.template?.warning === 'media_storage_failed'
        ? t('WHATSAPP_TEMPLATE_BUILDER.MEDIA_STORAGE_WARNING')
        : t('WHATSAPP_TEMPLATE_BUILDER.SUBMIT_SUCCESS')
    );
    emit('submitted');
    close();
  } catch (error) {
    useAlert(
      error.response?.data?.error || t('WHATSAPP_TEMPLATE_BUILDER.SUBMIT_ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};
watch(
  () => state.category,
  category => {
    if (category !== 'MARKETING') templateFormat.value = 'standard';
  }
);
watch(templateFormat, (format, previousFormat) => {
  saveFormatDraft(previousFormat);
  restoreFormatDraft(format);
  selectedSection.value = 'body';
});
watch(
  [catalogFormat, productTemplateType],
  ([format, productType], [previousFormat, previousProductType]) => {
    const previousKey = catalogDraftKey(previousFormat, previousProductType);
    catalogDrafts[previousKey] = currentFormatDraft();
    const nextKey = catalogDraftKey(format, productType);
    restoreDraft(catalogDrafts[nextKey]);
    if (format === 'products' && productType === 'mpm') {
      state.headerType = 'text';
    }
    selectedSection.value = 'body';
  }
);
watch(() => [activeCardIndex.value, state.cards.length], scrollToActiveCard);

onMounted(() => {
  state.inboxId =
    inboxOptions.value.length === 1 ? inboxOptions.value[0].value : '';
  open();
});
watch(
  () => state.inboxId,
  () => {
    fetchCatalogs();
    fetchFlows();
  }
);
watch(
  () => [
    step.value,
    state.category,
    state.inboxId,
    state.language,
    state.authenticationSecurityRecommendation,
    state.authenticationExpirationEnabled,
    state.authenticationCodeExpirationMinutes,
  ],
  () => {
    authenticationMetaPreview.value = null;
    fetchAuthenticationPreview();
  }
);
defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="6xl"
    overflow-y-auto
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleDialogClose"
  >
    <template #default>
      <div
        class="flex flex-col gap-7 min-h-[82vh] -m-6 p-7 bg-n-solid-2 bg-[radial-gradient(circle_at_1px_1px,rgba(120,120,120,0.09)_1px,transparent_0)] bg-[size:1.25rem_1.25rem] rounded-xl"
      >
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <Button
              v-if="step === 2"
              icon="i-lucide-arrow-left"
              color="slate"
              variant="faded"
              size="sm"
              :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.BACK')"
              @click="step = 1"
            />
            <div>
              <h2 class="text-xl font-semibold text-n-slate-12">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.TITLE') }}
              </h2>
              <p class="mt-1 text-sm text-n-slate-11">
                {{
                  step === 1
                    ? t('WHATSAPP_TEMPLATE_BUILDER.STEP_DETAILS')
                    : t('WHATSAPP_TEMPLATE_BUILDER.STEP_BUILDER')
                }}
              </p>
            </div>
          </div>
          <Button
            icon="i-lucide-x"
            color="slate"
            variant="outline"
            size="sm"
            :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CLOSE')"
            @click="close"
          />
        </div>

        <TemplateBasicsStep
          v-if="step === 1"
          v-model:state="state"
          :categories="categories"
          :inbox-options="inboxOptions"
          :languages="languages"
          :name-error="nameError"
          :can-continue="canContinue"
          @continue="continueToBuilder"
        />

        <div
          v-else
          class="grid flex-1 gap-8 lg:grid-cols-[minmax(0,1fr)_23rem] lg:items-start"
        >
          <div
            class="flex flex-col gap-3 order-2 p-4 border shadow-sm lg:order-1 rounded-2xl border-n-strong bg-n-alpha-3"
          >
            <div
              v-if="state.category === 'MARKETING'"
              class="grid grid-cols-3 gap-1 p-1 mb-1 rounded-xl bg-n-alpha-2"
            >
              <Button
                v-for="format in templateFormats"
                :key="format.value"
                :label="format.label"
                :icon="format.icon"
                :variant="templateFormat === format.value ? 'solid' : 'ghost'"
                :color="templateFormat === format.value ? 'teal' : 'slate'"
                class="justify-center"
                @click="templateFormat = format.value"
              />
            </div>
            <AuthenticationTemplateEditor
              v-if="state.category === 'AUTHENTICATION'"
              v-model:state="state"
              :authentication-otp-types="authenticationOtpTypes"
              @add-app="addAuthenticationApp"
              @remove-app="removeAuthenticationApp"
            />
            <CatalogTemplateEditor
              v-if="
                templateFormat === 'catalog' && state.category === 'MARKETING'
              "
              v-model:selected-catalog-id="selectedCatalogId"
              v-model:catalog-format="catalogFormat"
              v-model:product-template-type="productTemplateType"
              v-model:product-carousel-button-type="productCarouselButtonType"
              v-model:product-carousel-url="productCarouselUrl"
              :catalog-options="catalogOptions"
              :catalog-formats="catalogFormats"
              :product-carousel-button-types="productCarouselButtonTypes"
              :product-template-types="productTemplateTypes"
              :is-loading-catalogs="isLoadingCatalogs"
              :has-fetched-catalogs="hasFetchedCatalogs"
              :variable-indexes="variableIndexes"
              @fetch-catalogs="fetchCatalogs"
            />
            <StandardTemplateEditor
              v-if="
                state.category !== 'AUTHENTICATION' &&
                ['standard', 'catalog'].includes(templateFormat)
              "
              v-model:state="state"
              :visible-sections="visibleSections"
              :selected-section="selectedSection"
              :media-header-types="mediaHeaderTypes"
              :media-accept="mediaAccept"
              :template-format="templateFormat"
              :catalog-body-max-length="catalogBodyMaxLength"
              :body-variable-indexes="bodyVariableIndexes"
              :button-types="buttonTypes"
              :flow-options="flowOptions"
              :is-loading-flows="isLoadingFlows"
              :variable-indexes="variableIndexes"
              @toggle-section="toggleSection"
              @toggle-header-type="toggleHeaderType"
              @add-header-variable="addHeaderVariable"
              @handle-header-file="handleHeaderFile"
              @set-header-gif-mode="setHeaderGifMode"
              @add-body-variable="addBodyVariable"
              @remove-button="removeStandardButton"
              @fetch-flows="fetchFlows"
              @add-button="addStandardButton"
            />
            <CarouselTemplateEditor
              v-else-if="state.category !== 'AUTHENTICATION'"
              v-model:state="state"
              :body-variable-indexes="bodyVariableIndexes"
              :active-card-variable-indexes="activeCardVariableIndexes"
              :active-card-index="activeCardIndex"
              :carousel-media-accept="carouselMediaAccept"
              :carousel-action-types="carouselActionTypes"
              :carousel-action-by-value="carouselActionByValue"
              :is-card-complete="isCardComplete"
              :carousel-action-error="carouselActionError"
              :variable-indexes="variableIndexes"
              @add-body-variable="addBodyVariable"
              @set-media-type="setCarouselMediaType"
              @set-card-element="setCarouselEditorCardElement"
              @select-card="selectCarouselCard"
              @add-card="addCard"
              @delete-card="deleteCard"
              @duplicate-card="duplicateCard"
              @navigate-card="navigateCard"
              @handle-card-file="handleCardFile"
              @add-card-variable="addCardVariable"
              @toggle-action="toggleCarouselAction"
              @normalize-phone-number="normalizePhoneNumber"
            />
            <div class="flex flex-wrap items-center justify-end gap-3 pt-3">
              <Button
                :label="t('WHATSAPP_TEMPLATE_BUILDER.SAVE_DRAFT')"
                color="slate"
                variant="outline"
                type="button"
              /><Button
                :label="t('WHATSAPP_TEMPLATE_BUILDER.SUBMIT')"
                type="button"
                :is-loading="isSubmitting"
                :disabled="!isTemplateValid || isSubmitting"
                @click="submitCarouselTemplate"
              />
            </div>
          </div>

          <WhatsAppTemplatePhonePreview
            :state="state"
            :direction="direction"
            :authentication-preview-body="authenticationPreviewBody"
            :authentication-preview-footer="authenticationPreviewFooter"
            :authentication-preview-button="authenticationPreviewButton"
            :template-format="templateFormat"
            :catalog-format="catalogFormat"
            :product-template-type="productTemplateType"
            :product-carousel-button-type="productCarouselButtonType"
            :product-carousel-url="productCarouselUrl"
            :active-card-index="activeCardIndex"
            :carousel-action-by-value="carouselActionByValue"
            @select-card="selectCarouselCard"
            @navigate-card="navigateCard"
            @set-card-element="setCarouselPreviewCardElement"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
