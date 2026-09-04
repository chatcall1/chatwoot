<script setup>
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import FileUpload from 'vue-upload-component';

import InboxesAPI from 'dashboard/api/inboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import { useAlert } from 'dashboard/composables';

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
const flows = ref([]);
const isLoadingFlows = ref(false);
const activeCardIndex = ref(0);
const carouselEditorCardElements = new Map();
const carouselPreviewCardElements = new Map();
const isSubmitting = ref(false);
let nextCarouselCardId = 1;
const generateCarouselCardId = () => {
  const id = nextCarouselCardId;
  nextCarouselCardId += 1;
  return id;
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
  body: '',
  bodyExamples: {},
  footer: '',
  buttonText: '',
  buttonType: 'QUICK_REPLY',
  flowId: '',
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
  body: '',
  bodyExamples: {},
  footer: '',
  buttonText: '',
  buttonType: 'QUICK_REPLY',
  flowId: '',
});
const formatDrafts = reactive({
  standard: createFormatDraft(),
  carousel: createFormatDraft(),
  catalog: createFormatDraft(),
});
const saveFormatDraft = format => {
  formatDrafts[format] = {
    headerType: state.headerType,
    headerText: state.headerText,
    headerMediaUrl: state.headerMediaUrl,
    headerMediaName: state.headerMediaName,
    body: state.body,
    bodyExamples: { ...state.bodyExamples },
    footer: state.footer,
    buttonText: state.buttonText,
    buttonType: state.buttonType,
    flowId: state.flowId,
  };
};
const restoreFormatDraft = format => {
  const draft = formatDrafts[format];
  Object.assign(state, {
    ...draft,
    bodyExamples: { ...draft.bodyExamples },
  });
};

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
  { value: 'en', label: t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGES.ENGLISH') },
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
  headerTypes.value.filter(option => option.value !== 'none')
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
  } finally {
    isLoadingCatalogs.value = false;
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
const buttonTypes = computed(() => [
  {
    value: 'QUICK_REPLY',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.QUICK_REPLY'),
  },
  { value: 'URL', label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.URL') },
  {
    value: 'FLOW',
    label: t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.FLOW'),
  },
]);
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
const isValidPhoneNumber = value => /^\+[1-9]\d{6,14}$/.test(value);
const VARIABLE_PATTERN = /\{\{(\d+)\}\}/g;
const isValidTemplateText = (
  value,
  { maxLineBreaks, allowVariableAtEnd = false } = {}
) => {
  const text = value.trim();
  const variableIndexes = [...text.matchAll(VARIABLE_PATTERN)].map(match =>
    Number(match[1])
  );
  const uniqueIndexes = [...new Set(variableIndexes)];
  const hasInvalidVariable = /\{\{|\}\}/.test(
    text.replace(VARIABLE_PATTERN, '')
  );
  const hasSequentialVariables = uniqueIndexes.every(
    (index, position) => index === position + 1
  );
  const hasInvalidVariableBoundary =
    /^\s*\{\{\d+\}\}/.test(text) ||
    (!allowVariableAtEnd && /\{\{\d+\}\}\s*$/.test(text));
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
    [...value.matchAll(VARIABLE_PATTERN)].map(match => Number(match[1]))
  ),
];
const bodyVariableIndexes = computed(() => variableIndexes(state.body));
const activeCardVariableIndexes = computed(() =>
  variableIndexes(activeCard.value.body)
);
const hasCompleteExamples = (indexes, examples) =>
  indexes.every(index => !!examples[index]?.trim());
const isValidUrl = value => {
  try {
    const variables = [...value.matchAll(VARIABLE_PATTERN)];
    if (
      variables.length > 1 ||
      (variables.length === 1 && !value.endsWith('{{1}}'))
    ) {
      return false;
    }
    const url = new URL(value.replace(VARIABLE_PATTERN, 'example'));
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
  state.name && !/^[a-z0-9_]+$/.test(state.name)
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
    (catalogFormat.value !== 'product_carousel' ||
      productCarouselButtonType.value === 'SPM' ||
      (!!productCarouselUrl.text.trim() &&
        productCarouselUrl.text.trim().length <= 25 &&
        isValidUrl(productCarouselUrl.url) &&
        (!productCarouselUrl.url.includes('{{1}}') ||
          !!productCarouselUrl.example.trim())))
);
const isStandardValid = computed(
  () =>
    state.category === 'MARKETING' &&
    templateFormat.value === 'standard' &&
    state.buttonType === 'FLOW' &&
    !!state.flowId &&
    !!state.buttonText.trim() &&
    state.buttonText.trim().length <= 25 &&
    ['none', 'text'].includes(state.headerType) &&
    (state.headerType !== 'text' || !!state.headerText.trim()) &&
    !!state.body.trim() &&
    state.body.length <= 1024 &&
    isValidTemplateText(state.body) &&
    hasCompleteExamples(bodyVariableIndexes.value, state.bodyExamples)
);
const isTemplateValid = computed(
  () => isStandardValid.value || isCarouselValid.value || isCatalogValid.value
);
const direction = computed(() => (state.language === 'ar' ? 'rtl' : 'ltr'));

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
    ? sections.value.filter(
        section => !['header', 'buttons'].includes(section.key)
      )
    : sections.value
);

const open = () => dialogRef.value?.open();
const close = () => {
  dialogRef.value?.close();
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
};
const mediaAccept = computed(() => {
  if (state.headerType === 'video') return 'video/mp4,video/3gpp';
  if (state.headerType === 'document') return 'application/pdf';
  return 'image/jpeg,image/png';
});
const handleHeaderFile = file => {
  if (!file?.file) return;
  if (state.headerMediaUrl) URL.revokeObjectURL(state.headerMediaUrl);
  state.headerMediaUrl = URL.createObjectURL(file.file);
  state.headerMediaName = file.name;
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
  state.body = `${state.body}${state.body ? ' ' : ''}{{${
    bodyVariableIndexes.value.length + 1
  }}}}`;
};
const addCardVariable = () => {
  const variables = activeCard.value.body.match(/\{\{\d+\}\}/g) || [];
  activeCard.value.body = `${activeCard.value.body}${
    activeCard.value.body ? ' ' : ''
  }{{${variables.length + 1}}}`;
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
    body: state.body,
    media_type: state.carouselMediaType.toUpperCase(),
    card_text_enabled: state.carouselTextEnabled,
    button_types: state.carouselButtonTypes,
    cards: state.cards.map(card => ({
      body: state.carouselTextEnabled ? card.body : '',
      body_examples: state.carouselTextEnabled
        ? variableIndexes(card.body).map(index => card.bodyExamples[index])
        : [],
      buttons: card.buttons,
    })),
    body_examples: bodyVariableIndexes.value.map(
      index => state.bodyExamples[index]
    ),
  };
  if (templateFormat.value === 'standard') {
    delete template.media_type;
    delete template.card_text_enabled;
    delete template.button_types;
    delete template.cards;
    template.template_format = 'standard';
    template.header_type = state.headerType;
    template.header_text = state.headerText;
    template.footer = state.footer;
    template.button = {
      type: 'FLOW',
      text: state.buttonText,
      flow_id: state.flowId,
    };
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
  }
  formData.append('template', JSON.stringify(template));
  if (templateFormat.value === 'carousel') {
    state.cards.forEach((card, index) => {
      formData.append(`media_${index}`, card.mediaFile);
    });
  }

  try {
    await InboxesAPI.createMessageTemplate(state.inboxId, formData);
    useAlert(t('WHATSAPP_TEMPLATE_BUILDER.SUBMIT_SUCCESS'));
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
defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="6xl"
    overflow-y-auto
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="emit('close')"
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

        <div v-if="step === 1" class="grid w-full max-w-4xl gap-8 mx-auto pt-8">
          <section class="grid gap-4">
            <h3 class="text-base font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.CATEGORY_LABEL') }}
            </h3>
            <div class="grid grid-cols-1 gap-3 md:grid-cols-3">
              <button
                v-for="category in categories"
                :key="category.value"
                type="button"
                class="flex items-center gap-3 p-4 text-start border-2 border-solid rounded-xl shadow-sm transition-all bg-n-alpha-3"
                :class="
                  state.category === category.value
                    ? 'border-[#2f9683] shadow-md bg-n-brand/5'
                    : 'border-[#cbd5e1] hover:border-[#94a3b8] hover:shadow-md'
                "
                @click="state.category = category.value"
              >
                <span
                  class="grid rounded-lg size-11 shrink-0 place-items-center"
                  :class="
                    state.category === category.value
                      ? 'bg-n-brand/10 text-n-brand'
                      : 'bg-n-alpha-2 text-n-slate-11'
                  "
                >
                  <Icon :icon="category.icon" class="size-5" />
                </span>
                <span class="flex flex-col min-w-0 gap-1">
                  <span class="text-sm font-semibold text-n-slate-12">
                    {{ category.label }}
                  </span>
                  <span class="text-xs text-n-slate-10">
                    {{ category.description }}
                  </span>
                </span>
                <span
                  class="grid ms-auto border-2 border-solid rounded-full size-5 shrink-0 place-items-center"
                  :class="
                    state.category === category.value
                      ? 'border-n-brand bg-n-brand text-white'
                      : 'border-n-strong'
                  "
                >
                  <Icon
                    v-if="state.category === category.value"
                    icon="i-lucide-check"
                    class="size-3"
                  />
                </span>
              </button>
            </div>
          </section>

          <section class="grid gap-4">
            <h3 class="text-base font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.BASIC_SETTINGS') }}
            </h3>
            <div
              class="grid gap-5 p-5 border shadow-sm md:grid-cols-3 rounded-xl border-n-strong bg-n-alpha-3"
            >
              <div class="flex flex-col gap-1">
                <label class="mb-0.5 text-heading-3 text-n-slate-12">
                  {{ t('WHATSAPP_TEMPLATE_BUILDER.INBOX.LABEL') }}
                </label>
                <ComboBox
                  v-model="state.inboxId"
                  :options="inboxOptions"
                  :placeholder="
                    t('WHATSAPP_TEMPLATE_BUILDER.INBOX.PLACEHOLDER')
                  "
                />
                <span v-if="!inboxOptions.length" class="text-xs text-n-ruby-9">
                  {{ t('WHATSAPP_TEMPLATE_BUILDER.INBOX.EMPTY') }}
                </span>
              </div>
              <Input
                v-model="state.name"
                :label="t('WHATSAPP_TEMPLATE_BUILDER.NAME.LABEL')"
                :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.NAME.PLACEHOLDER')"
                :message="
                  nameError || t('WHATSAPP_TEMPLATE_BUILDER.NAME.HELPER')
                "
                :message-type="nameError ? 'error' : 'info'"
                @input="
                  state.name = state.name
                    .toLowerCase()
                    .replace(/[^a-z0-9_]/g, '')
                "
              />
              <div class="flex flex-col gap-1">
                <label class="mb-0.5 text-heading-3 text-n-slate-12">
                  {{ t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGE_LABEL') }}
                </label>
                <ComboBox
                  v-model="state.language"
                  :options="languages"
                  :placeholder="
                    t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGE_PLACEHOLDER')
                  "
                />
              </div>
            </div>
          </section>
          <div class="flex justify-end">
            <Button
              :label="t('WHATSAPP_TEMPLATE_BUILDER.CONTINUE')"
              icon="i-lucide-arrow-right"
              trailing-icon
              :disabled="!canContinue"
              @click="continueToBuilder"
            />
          </div>
        </div>

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
            <template v-if="templateFormat === 'catalog'">
              <section
                class="grid gap-3 p-4 border rounded-xl border-n-strong bg-n-alpha-1"
              >
                <div
                  class="flex items-start gap-3 p-3 rounded-lg bg-n-blue-2 text-n-blue-12"
                >
                  <Icon icon="i-lucide-info" class="mt-0.5 size-4 shrink-0" />
                  <p class="text-xs leading-5">
                    {{ t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.REQUIREMENT') }}
                  </p>
                </div>
                <div class="flex items-end gap-2">
                  <ComboBox
                    v-model="selectedCatalogId"
                    class="flex-1"
                    :options="catalogOptions"
                    :label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.SELECT_LABEL')"
                    :placeholder="
                      t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.SELECT_PLACEHOLDER')
                    "
                    :disabled="isLoadingCatalogs"
                  />
                  <Button
                    icon="i-lucide-refresh-cw"
                    color="slate"
                    variant="outline"
                    :is-loading="isLoadingCatalogs"
                    :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.FETCH')"
                    @click="fetchCatalogs"
                  />
                </div>
                <div class="grid grid-cols-1 gap-2 md:grid-cols-2">
                  <button
                    v-for="format in catalogFormats"
                    :key="format.value"
                    type="button"
                    class="flex items-center gap-3 p-3 text-start border-2 border-solid rounded-xl transition-colors"
                    :class="
                      catalogFormat === format.value
                        ? 'border-n-brand bg-n-brand/5'
                        : 'border-n-slate-8 hover:border-n-slate-10'
                    "
                    @click="catalogFormat = format.value"
                  >
                    <span
                      class="grid rounded-lg size-10 shrink-0 place-items-center bg-n-alpha-2 text-n-brand"
                    >
                      <Icon :icon="format.icon" class="size-5" />
                    </span>
                    <span class="flex flex-col gap-1">
                      <span class="text-sm font-semibold text-n-slate-12">{{
                        format.label
                      }}</span>
                      <span class="text-xs text-n-slate-10">{{
                        format.description
                      }}</span>
                    </span>
                  </button>
                </div>
                <div
                  v-if="catalogFormat === 'catalog_template'"
                  class="flex items-start gap-3 p-3 border rounded-lg border-n-weak bg-n-alpha-1"
                >
                  <Icon
                    icon="i-lucide-shopping-bag"
                    class="mt-0.5 size-4 shrink-0 text-n-brand"
                  />
                  <p class="text-xs leading-5 text-n-slate-11">
                    {{
                      t(
                        'WHATSAPP_TEMPLATE_BUILDER.CATALOG.CATALOG_BUTTON_HELPER'
                      )
                    }}
                  </p>
                </div>
                <div
                  v-if="catalogFormat === 'product_carousel'"
                  class="grid gap-3 p-3 border rounded-lg border-n-weak bg-n-alpha-1"
                >
                  <p class="text-xs leading-5 text-n-slate-11">
                    {{
                      t(
                        'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_CAROUSEL_HELPER'
                      )
                    }}
                  </p>
                  <div class="grid grid-cols-2 gap-2">
                    <button
                      v-for="buttonType in productCarouselButtonTypes"
                      :key="buttonType.value"
                      type="button"
                      class="p-3 text-sm text-start border-2 border-solid rounded-lg"
                      :class="
                        productCarouselButtonType === buttonType.value
                          ? 'border-n-brand bg-n-brand/5 text-n-brand'
                          : 'border-n-slate-8 text-n-slate-12 hover:border-n-slate-10'
                      "
                      @click="productCarouselButtonType = buttonType.value"
                    >
                      {{ buttonType.label }}
                    </button>
                  </div>
                  <div
                    v-if="productCarouselButtonType === 'URL'"
                    class="grid gap-3 md:grid-cols-2"
                  >
                    <Input
                      v-model="productCarouselUrl.text"
                      :label="
                        t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT')
                      "
                      :placeholder="
                        t(
                          'WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT_PLACEHOLDER'
                        )
                      "
                    />
                    <Input
                      v-model="productCarouselUrl.url"
                      :label="
                        t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_VALUE')
                      "
                      :placeholder="
                        t(
                          'WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_PLACEHOLDER'
                        )
                      "
                    />
                    <Input
                      v-if="productCarouselUrl.url.includes('{{1}}')"
                      v-model="productCarouselUrl.example"
                      :label="
                        t(
                          'WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_EXAMPLE'
                        )
                      "
                    />
                  </div>
                </div>
                <div
                  v-if="catalogFormat === 'products'"
                  class="grid grid-cols-1 gap-2 md:grid-cols-2"
                >
                  <button
                    v-for="type in productTemplateTypes"
                    :key="type.value"
                    type="button"
                    class="flex items-center gap-3 p-3 text-start border-2 border-solid rounded-xl"
                    :class="
                      productTemplateType === type.value
                        ? 'border-n-brand bg-n-brand/5'
                        : 'border-n-slate-8 hover:border-n-slate-10'
                    "
                    @click="productTemplateType = type.value"
                  >
                    <Icon :icon="type.icon" class="size-5 text-n-brand" />
                    <span>
                      <span class="block text-sm font-semibold text-n-slate-12">
                        {{ type.label }}
                      </span>
                      <span class="block mt-1 text-xs text-n-slate-10">{{
                        type.description
                      }}</span>
                    </span>
                  </button>
                </div>
              </section>
            </template>
            <template
              v-if="
                templateFormat === 'standard' || templateFormat === 'catalog'
              "
            >
              <div
                v-for="section in visibleSections"
                :key="section.key"
                class="border rounded-xl border-n-strong bg-n-alpha-1"
              >
                <button
                  type="button"
                  class="flex items-center justify-between w-full gap-3 p-4 text-start"
                  @click="toggleSection(section.key)"
                >
                  <span
                    class="flex items-center gap-2 text-sm font-medium text-n-slate-12"
                    ><Icon
                      :icon="
                        selectedSection === section.key
                          ? 'i-lucide-chevron-up'
                          : 'i-lucide-chevron-down'
                      "
                      class="size-4"
                    />
                    {{ section.label }}
                    <span
                      v-if="section.optional"
                      class="text-xs font-normal text-n-slate-10"
                    >
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.OPTIONAL') }}
                    </span>
                  </span>
                </button>
                <div v-if="selectedSection === section.key" class="p-4 pt-0">
                  <template v-if="section.key === 'header'">
                    <div
                      class="grid grid-cols-4 gap-1 p-1 rounded-lg bg-n-alpha-2"
                    >
                      <Button
                        v-for="headerType in mediaHeaderTypes"
                        :key="headerType.value"
                        :label="headerType.label"
                        :variant="
                          state.headerType === headerType.value
                            ? 'solid'
                            : 'ghost'
                        "
                        :color="
                          state.headerType === headerType.value
                            ? 'teal'
                            : 'slate'
                        "
                        size="sm"
                        class="justify-center"
                        @click="toggleHeaderType(headerType.value)"
                      />
                    </div>
                    <Input
                      v-if="state.headerType === 'text'"
                      v-model="state.headerText"
                      class="mt-3"
                      :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TEXT_LABEL')"
                      :placeholder="
                        t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TEXT_PLACEHOLDER')
                      "
                    />
                    <FileUpload
                      v-else-if="
                        ['image', 'video', 'document'].includes(
                          state.headerType
                        )
                      "
                      input-id="whatsappTemplateHeaderMedia"
                      :accept="mediaAccept"
                      :multiple="false"
                      :drop-directory="false"
                      class="block mt-3"
                      @input-file="handleHeaderFile"
                    >
                      <div
                        class="flex items-center justify-between gap-4 p-4 border border-dashed cursor-pointer rounded-xl border-n-strong bg-n-alpha-1 hover:border-n-brand"
                      >
                        <span class="flex flex-col gap-1">
                          <span class="text-sm font-medium text-n-slate-12">
                            {{ t('WHATSAPP_TEMPLATE_BUILDER.HEADER.UPLOAD') }}
                          </span>
                          <span class="text-xs text-n-slate-10">
                            {{
                              state.headerMediaName ||
                              t(
                                'WHATSAPP_TEMPLATE_BUILDER.HEADER.UPLOAD_HELPER'
                              )
                            }}
                          </span>
                        </span>
                        <span
                          class="grid border rounded-lg size-10 shrink-0 place-items-center border-n-strong bg-n-alpha-3"
                        >
                          <Icon icon="i-lucide-upload" class="size-5" />
                        </span>
                      </div>
                    </FileUpload>
                  </template>
                  <Editor
                    v-else-if="section.key === 'body'"
                    v-model="state.body"
                    :placeholder="
                      t('WHATSAPP_TEMPLATE_BUILDER.BODY.PLACEHOLDER')
                    "
                    :max-length="
                      templateFormat === 'catalog' ? catalogBodyMaxLength : 1024
                    "
                    channel-type="Context::Plain"
                  />
                  <Input
                    v-else-if="section.key === 'footer'"
                    v-model="state.footer"
                    :maxlength="60"
                    :label="t('WHATSAPP_TEMPLATE_BUILDER.FOOTER.LABEL')"
                    :placeholder="
                      t('WHATSAPP_TEMPLATE_BUILDER.FOOTER.PLACEHOLDER')
                    "
                  />
                  <div v-else class="grid gap-3">
                    <ComboBox
                      v-model="state.buttonType"
                      :options="buttonTypes"
                      :placeholder="
                        t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPE_PLACEHOLDER')
                      "
                    /><Input
                      v-model="state.buttonText"
                      :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_LABEL')"
                      :placeholder="
                        t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_PLACEHOLDER')
                      "
                    />
                    <div v-if="state.buttonType === 'FLOW'" class="grid gap-2">
                      <p class="text-sm font-medium text-n-slate-12">
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_LABEL') }}
                      </p>
                      <div class="flex items-end gap-2">
                        <ComboBox
                          v-model="state.flowId"
                          class="grow"
                          :options="flowOptions"
                          :placeholder="
                            t(
                              'WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_PLACEHOLDER'
                            )
                          "
                        />
                        <Button
                          :label="
                            t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FETCH_FLOWS')
                          "
                          icon="i-lucide-refresh-cw"
                          color="slate"
                          variant="outline"
                          :is-loading="isLoadingFlows"
                          @click="fetchFlows"
                        />
                      </div>
                      <p class="text-xs text-n-slate-10">
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_HELPER') }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </template>
            <template v-else>
              <div
                class="grid gap-3 p-4 border-2 rounded-xl border-n-slate-8 bg-n-alpha-1"
              >
                <div class="flex items-center justify-between gap-3">
                  <span>
                    <h3 class="text-sm font-semibold text-n-slate-12">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.BODY') }}
                    </h3>
                    <p class="mt-1 text-xs text-n-slate-10">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.BODY_HELPER') }}
                    </p>
                  </span>
                  <Button
                    :label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_VARIABLE')
                    "
                    icon="i-lucide-braces"
                    color="teal"
                    variant="ghost"
                    size="sm"
                    @click="addBodyVariable"
                  />
                </div>
                <Editor
                  v-model="state.body"
                  :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.BODY.PLACEHOLDER')"
                  :max-length="1024"
                  channel-type="Context::Plain"
                />
                <div
                  v-if="bodyVariableIndexes.length"
                  class="grid gap-3 sm:grid-cols-2"
                >
                  <Input
                    v-for="index in bodyVariableIndexes"
                    :key="index"
                    v-model="state.bodyExamples[index]"
                    :label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE', {
                        n: index,
                      })
                    "
                    :placeholder="
                      t(
                        'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE_PLACEHOLDER'
                      )
                    "
                  />
                </div>
              </div>
              <div
                class="flex flex-col gap-5 p-4 border rounded-xl border-n-strong bg-n-alpha-1"
              >
                <div class="flex items-center justify-between gap-3">
                  <div>
                    <h3 class="text-sm font-semibold text-n-slate-12">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.TITLE') }}
                    </h3>
                    <p class="mt-1 text-xs text-n-slate-10">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DESCRIPTION') }}
                    </p>
                  </div>
                  <span class="text-xs text-n-slate-10">
                    {{
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COUNT', {
                        current: state.cards.length,
                      })
                    }}
                  </span>
                </div>
                <div
                  class="flex flex-wrap items-center justify-between gap-3 p-3 rounded-lg bg-n-alpha-2"
                >
                  <div class="flex items-center gap-2">
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.MEDIA') }}
                    </span>
                    <Button
                      :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.IMAGE')"
                      icon="i-lucide-image"
                      size="sm"
                      :variant="
                        state.carouselMediaType === 'image' ? 'solid' : 'ghost'
                      "
                      :color="
                        state.carouselMediaType === 'image' ? 'teal' : 'slate'
                      "
                      @click="setCarouselMediaType('image')"
                    />
                    <Button
                      :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.VIDEO')"
                      icon="i-lucide-video"
                      size="sm"
                      :variant="
                        state.carouselMediaType === 'video' ? 'solid' : 'ghost'
                      "
                      :color="
                        state.carouselMediaType === 'video' ? 'teal' : 'slate'
                      "
                      @click="setCarouselMediaType('video')"
                    />
                  </div>
                  <label
                    class="flex items-center gap-2 text-xs font-medium cursor-pointer text-n-slate-11"
                  >
                    <Switch v-model="state.carouselTextEnabled" />
                    {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_TEXT') }}
                  </label>
                </div>
                <div class="flex gap-3 pb-2 overflow-x-auto">
                  <button
                    v-for="(card, index) in state.cards"
                    :key="card.id"
                    :ref="
                      element => setCarouselEditorCardElement(card.id, element)
                    "
                    type="button"
                    class="w-36 overflow-hidden text-start border-2 rounded-xl shrink-0 bg-n-alpha-3 transition-colors"
                    :class="
                      activeCardIndex === index
                        ? 'border-[#00a884] shadow-sm'
                        : 'border-[#cbd5e1] hover:border-[#94a3b8]'
                    "
                    @click="selectCarouselCard(index)"
                  >
                    <div class="grid h-20 place-items-center bg-n-alpha-2">
                      <img
                        v-if="
                          card.mediaUrl &&
                          card.mediaMimeType.startsWith('image/')
                        "
                        :src="card.mediaUrl"
                        class="object-cover w-full h-full"
                      />
                      <video
                        v-else-if="card.mediaUrl"
                        :src="card.mediaUrl"
                        class="object-cover w-full h-full"
                        muted
                      />
                      <Icon
                        v-else
                        icon="i-lucide-image"
                        class="size-6 text-n-slate-10"
                      />
                    </div>
                    <p class="p-2 text-xs font-medium text-n-slate-12">
                      {{
                        t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD', {
                          n: index + 1,
                        })
                      }}
                    </p>
                    <p class="px-2 pb-2 text-[0.65rem] text-n-slate-10">
                      {{
                        isCardComplete(card)
                          ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COMPLETE')
                          : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.INCOMPLETE')
                      }}
                    </p>
                  </button>
                  <button
                    v-if="state.cards.length < 10"
                    type="button"
                    class="grid w-28 border border-dashed rounded-xl shrink-0 min-h-28 place-items-center border-n-strong text-n-slate-10 hover:border-n-brand hover:text-n-brand"
                    @click="addCard"
                  >
                    <span class="flex flex-col items-center gap-2 text-xs">
                      <Icon icon="i-lucide-plus" class="size-5" />
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_CARD') }}
                    </span>
                  </button>
                </div>
                <div
                  class="flex items-center gap-1 py-2 border-t border-n-weak"
                >
                  <Button
                    icon="i-lucide-trash-2"
                    color="slate"
                    variant="ghost"
                    size="sm"
                    :disabled="state.cards.length <= 2"
                    :aria-label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DELETE_CARD')
                    "
                    @click="deleteCard"
                  />
                  <Button
                    icon="i-lucide-copy"
                    color="slate"
                    variant="ghost"
                    size="sm"
                    :disabled="state.cards.length >= 10"
                    :aria-label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DUPLICATE_CARD')
                    "
                    @click="duplicateCard"
                  />
                  <Button
                    icon="i-lucide-chevron-left"
                    color="slate"
                    variant="ghost"
                    size="sm"
                    :disabled="activeCardIndex === 0"
                    :aria-label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.PREVIOUS_CARD')
                    "
                    @click="navigateCard(-1)"
                  />
                  <Button
                    icon="i-lucide-chevron-right"
                    color="slate"
                    variant="ghost"
                    size="sm"
                    :disabled="activeCardIndex === state.cards.length - 1"
                    :aria-label="
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.NEXT_CARD')
                    "
                    @click="navigateCard(1)"
                  />
                </div>
                <div class="grid gap-4 pt-4 border-t border-n-weak">
                  <h4 class="text-sm font-semibold text-n-slate-12">
                    {{
                      t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD', {
                        n: activeCardIndex + 1,
                      })
                    }}
                  </h4>
                  <p class="-mt-3 text-xs text-n-slate-10">
                    {{
                      isCardComplete(activeCard)
                        ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COMPLETE')
                        : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.INCOMPLETE')
                    }}
                  </p>
                  <FileUpload
                    :input-id="`whatsappCarouselCard${activeCardIndex}`"
                    :accept="carouselMediaAccept"
                    :size="
                      (state.carouselMediaType === 'video' ? 16 : 5) *
                      1024 *
                      1024
                    "
                    :multiple="false"
                    :drop-directory="false"
                    @input-file="file => handleCardFile(file, activeCardIndex)"
                  >
                    <div
                      class="flex items-center justify-between p-4 border border-dashed cursor-pointer rounded-xl border-n-strong hover:border-n-brand"
                    >
                      <span class="text-sm text-n-slate-12">
                        {{
                          state.cards[activeCardIndex].mediaName ||
                          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.UPLOAD_MEDIA')
                        }}
                      </span>
                      <Icon icon="i-lucide-upload" class="size-5" />
                    </div>
                  </FileUpload>
                  <p class="-mt-3 text-xs text-n-slate-10">
                    {{
                      state.carouselMediaType === 'video'
                        ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VIDEO_HELPER')
                        : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.IMAGE_HELPER')
                    }}
                  </p>
                  <div v-if="state.carouselTextEnabled" class="grid gap-2">
                    <div class="flex items-center justify-between gap-2">
                      <span class="text-sm font-medium text-n-slate-12">
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY') }}
                      </span>
                      <span class="flex items-center gap-3">
                        <Button
                          :label="
                            t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_VARIABLE')
                          "
                          icon="i-lucide-braces"
                          color="teal"
                          variant="ghost"
                          size="sm"
                          @click="addCardVariable"
                        />
                        <span class="text-xs text-n-slate-10">
                          {{
                            t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.TEXT_COUNT', {
                              current: activeCard.body.length,
                            })
                          }}
                        </span>
                      </span>
                    </div>
                    <Editor
                      v-model="activeCard.body"
                      :placeholder="
                        t(
                          'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY_PLACEHOLDER'
                        )
                      "
                      :max-length="160"
                      channel-type="Context::Plain"
                    />
                    <div
                      v-if="activeCardVariableIndexes.length"
                      class="grid gap-3 sm:grid-cols-2"
                    >
                      <Input
                        v-for="index in activeCardVariableIndexes"
                        :key="index"
                        v-model="activeCard.bodyExamples[index]"
                        :label="
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE',
                            { n: index }
                          )
                        "
                        :placeholder="
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE_PLACEHOLDER'
                          )
                        "
                      />
                    </div>
                  </div>
                  <div class="grid gap-3 pt-4 border-t border-n-weak">
                    <div>
                      <h4 class="text-sm font-semibold text-n-slate-12">
                        {{
                          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.TITLE')
                        }}
                      </h4>
                      <p class="mt-1 text-xs text-n-slate-10">
                        {{
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.DESCRIPTION'
                          )
                        }}
                      </p>
                    </div>
                    <div class="grid gap-2 sm:grid-cols-3">
                      <Button
                        v-for="action in carouselActionTypes"
                        :key="action.value"
                        :label="action.label"
                        :icon="action.icon"
                        size="sm"
                        :variant="
                          state.carouselButtonTypes.includes(action.value)
                            ? 'solid'
                            : 'outline'
                        "
                        :color="
                          state.carouselButtonTypes.includes(action.value)
                            ? 'teal'
                            : 'slate'
                        "
                        :disabled="
                          state.carouselButtonTypes.length >= 2 &&
                          !state.carouselButtonTypes.includes(action.value)
                        "
                        @click="toggleCarouselAction(action.value)"
                      />
                    </div>
                    <div
                      v-for="action in state.carouselButtonTypes"
                      :key="action"
                      class="grid gap-3 p-3 border rounded-lg border-n-strong sm:grid-cols-2"
                    >
                      <Input
                        v-model="activeCard.buttons[action].text"
                        :label="carouselActionByValue[action].label"
                        :placeholder="
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_PLACEHOLDER'
                          )
                        "
                        maxlength="25"
                        :message="
                          activeCard.buttons[action].text.length
                            ? t(
                                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.TEXT_HELPER',
                                {
                                  current:
                                    activeCard.buttons[action].text.length,
                                }
                              )
                            : ''
                        "
                      />
                      <Input
                        v-if="action !== 'QUICK_REPLY'"
                        v-model="activeCard.buttons[action].value"
                        :type="action === 'PHONE_NUMBER' ? 'tel' : 'url'"
                        :label="carouselActionByValue[action].valueLabel"
                        :placeholder="
                          carouselActionByValue[action].valuePlaceholder
                        "
                        :message="
                          carouselActionError(action) ||
                          (action === 'PHONE_NUMBER'
                            ? t(
                                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE_HELPER'
                              )
                            : t(
                                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_HELPER'
                              ))
                        "
                        :message-type="
                          carouselActionError(action) ? 'error' : 'info'
                        "
                        dir="ltr"
                        @input="
                          action === 'PHONE_NUMBER' &&
                            normalizePhoneNumber($event)
                        "
                      />
                      <Input
                        v-if="
                          action === 'URL' &&
                          variableIndexes(activeCard.buttons.URL.value).length
                        "
                        v-model="activeCard.buttons.URL.example"
                        :label="
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_EXAMPLE'
                          )
                        "
                        :placeholder="
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_EXAMPLE_PLACEHOLDER'
                          )
                        "
                      />
                    </div>
                  </div>
                </div>
              </div>
            </template>
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

          <div
            class="flex flex-col items-center gap-3 order-1 lg:order-2 lg:sticky lg:top-0"
          >
            <p class="text-sm font-medium text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TITLE') }}
            </p>
            <p class="-mt-2 text-xs text-center text-n-slate-10">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.DESCRIPTION') }}
            </p>
            <div
              class="relative w-[20rem] h-[39rem] p-[0.45rem] border-[0.2rem] border-[#d6d8da] rounded-[2.8rem] bg-[#f7f7f7] shadow-[0_1.5rem_3rem_rgba(31,41,55,0.18)]"
            >
              <div
                class="absolute z-20 w-24 h-5 -translate-x-1/2 bg-[#f7f7f7] rounded-b-2xl top-1 left-1/2"
              />
              <div
                class="flex flex-col h-full overflow-hidden rounded-[2.25rem] bg-[#efeae2]"
                :dir="direction"
              >
                <div
                  class="flex items-center justify-between h-7 px-5 text-[0.65rem] font-semibold text-[#111827] bg-[#f7f9fa]"
                >
                  <span>{{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}</span>
                  <span class="flex items-center gap-1" dir="ltr">
                    <Icon icon="i-lucide-signal" class="size-3" />
                    <span>{{
                      t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.NETWORK')
                    }}</span>
                    <Icon icon="i-lucide-battery-full" class="size-3.5" />
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 px-3 py-2.5 border-b border-[#dde2e5] bg-[#f7f9fa] text-[#111827]"
                >
                  <Icon
                    icon="i-lucide-chevron-left"
                    class="size-5 text-[#55747d]"
                  />
                  <span
                    class="grid rounded-full size-10 shrink-0 place-items-center bg-[#dff5f2] text-xs font-semibold text-[#08776d] ring-1 ring-[#b7e2dc]"
                  >
                    {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.AVATAR') }}
                  </span>
                  <span class="flex flex-col min-w-0 grow">
                    <span class="text-sm font-semibold truncate">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BUSINESS') }}
                    </span>
                    <span class="text-[0.6rem] text-[#667781]">
                      {{
                        t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BUSINESS_SUBTITLE')
                      }}
                    </span>
                  </span>
                  <Icon icon="i-lucide-store" class="size-5 text-[#55747d]" />
                  <Icon
                    icon="i-lucide-more-vertical"
                    class="size-5 text-[#55747d]"
                  />
                </div>
                <div
                  class="flex flex-col flex-1 gap-3 p-3 bg-[#efeae2] bg-[radial-gradient(circle_at_20%_20%,rgba(120,103,82,0.08)_1px,transparent_1px)] bg-[size:1rem_1rem]"
                >
                  <div
                    class="self-center px-2.5 py-1 text-[0.6rem] rounded-md shadow-sm bg-white/90 text-[#667781]"
                  >
                    {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TODAY') }}
                  </div>
                  <div
                    v-if="
                      templateFormat === 'catalog' &&
                      catalogFormat === 'product_carousel'
                    "
                    class="flex flex-col gap-2 overflow-hidden"
                  >
                    <div
                      class="self-start max-w-[92%] p-3 text-xs bg-white shadow-sm rounded-xl rounded-ss-sm text-[#111827]"
                    >
                      {{
                        state.body ||
                        t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY')
                      }}
                    </div>
                    <div class="flex gap-2 overflow-hidden">
                      <div
                        v-for="index in 2"
                        :key="index"
                        class="w-44 overflow-hidden text-start bg-white border border-[#c9d1d5] shrink-0 rounded-xl shadow-sm"
                      >
                        <div
                          class="grid h-24 place-items-center bg-[#e9edef] text-[#8696a0]"
                        >
                          <Icon icon="i-lucide-package" class="size-7" />
                        </div>
                        <div class="p-3 text-xs text-[#111827]">
                          <p class="font-medium">
                            {{
                              t(
                                'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRODUCT',
                                { n: index }
                              )
                            }}
                          </p>
                          <p class="mt-1 text-[0.65rem] text-[#667781]">
                            {{
                              t(
                                'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRICE'
                              )
                            }}
                          </p>
                        </div>
                        <div
                          class="px-3 py-2 border-t border-[#e9edef] text-center text-xs font-medium text-[#00a884]"
                        >
                          {{
                            productCarouselButtonType === 'SPM'
                              ? t(
                                  'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_PRODUCT'
                                )
                              : productCarouselUrl.text ||
                                t(
                                  'WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT_PLACEHOLDER'
                                )
                          }}
                        </div>
                      </div>
                    </div>
                  </div>
                  <div
                    v-else-if="templateFormat === 'catalog'"
                    class="self-start max-w-[92%] overflow-hidden rounded-xl rounded-ss-sm bg-white shadow-sm text-xs text-[#111827]"
                  >
                    <div
                      v-if="
                        catalogFormat === 'catalog_template' ||
                        productTemplateType === 'spm'
                      "
                      class="grid h-28 place-items-center bg-[#e9edef] text-[#8696a0]"
                    >
                      <span class="flex flex-col items-center gap-2">
                        <Icon icon="i-lucide-package" class="size-7" />
                        {{
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRODUCT_MEDIA'
                          )
                        }}
                      </span>
                    </div>
                    <div class="p-3">
                      <p>
                        {{
                          state.body ||
                          t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY')
                        }}
                      </p>
                      <p
                        v-if="state.footer"
                        class="mt-2 text-[0.65rem] text-[#667781]"
                      >
                        {{ state.footer }}
                      </p>
                      <span
                        class="block mt-2 text-[0.58rem] text-end text-[#8696a0]"
                      >
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
                      </span>
                    </div>
                    <div
                      class="px-3 py-2.5 border-t border-[#e9edef] text-center font-medium text-[#00a884]"
                    >
                      {{
                        catalogFormat === 'catalog_template'
                          ? t(
                              'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_CATALOG'
                            )
                          : productTemplateType === 'mpm'
                            ? t(
                                'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_ITEMS'
                              )
                            : t(
                                'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_PRODUCT'
                              )
                      }}
                    </div>
                  </div>
                  <div
                    v-else-if="templateFormat === 'carousel'"
                    class="flex flex-col gap-2 overflow-hidden"
                  >
                    <div
                      class="self-start max-w-[92%] p-3 text-xs bg-white shadow-sm rounded-xl rounded-ss-sm text-[#111827]"
                    >
                      {{
                        state.body ||
                        t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY')
                      }}
                    </div>
                    <div class="relative">
                      <div
                        class="overflow-hidden scroll-smooth"
                        :dir="direction"
                      >
                        <div class="flex gap-2">
                          <button
                            v-for="(card, index) in state.cards"
                            :key="card.id"
                            :ref="
                              element =>
                                setCarouselPreviewCardElement(card.id, element)
                            "
                            type="button"
                            class="w-44 overflow-hidden text-start bg-white border-2 shrink-0 rounded-xl shadow-sm transition-colors"
                            :class="
                              index === activeCardIndex
                                ? 'border-[#00a884] shadow-md'
                                : 'border-[#c9d1d5]'
                            "
                            :dir="direction"
                            @click="selectCarouselCard(index)"
                          >
                            <div
                              class="grid h-28 place-items-center bg-[#e9edef] text-[#8696a0]"
                            >
                              <img
                                v-if="
                                  card.mediaUrl &&
                                  card.mediaMimeType.startsWith('image/')
                                "
                                :src="card.mediaUrl"
                                class="object-cover w-full h-full"
                              />
                              <video
                                v-else-if="card.mediaUrl"
                                :src="card.mediaUrl"
                                class="object-cover w-full h-full"
                                muted
                              />
                              <Icon
                                v-else
                                :icon="
                                  state.carouselMediaType === 'video'
                                    ? 'i-lucide-video'
                                    : 'i-lucide-image'
                                "
                                class="size-7"
                              />
                            </div>
                            <div
                              v-if="state.carouselTextEnabled"
                              class="p-3 text-xs text-[#111827]"
                            >
                              <p>
                                {{
                                  card.body ||
                                  t(
                                    'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY_PREVIEW'
                                  )
                                }}
                              </p>
                              <span
                                class="block mt-2 text-[0.58rem] text-end text-[#8696a0]"
                              >
                                {{
                                  t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME')
                                }}
                              </span>
                            </div>
                            <div
                              v-for="action in state.carouselButtonTypes"
                              :key="action"
                              class="px-3 py-2 border-t border-[#e9edef] text-center text-xs font-medium text-[#00a884]"
                            >
                              {{
                                card.buttons[action].text ||
                                carouselActionByValue[action].label
                              }}
                            </div>
                          </button>
                        </div>
                      </div>
                      <Button
                        v-if="activeCardIndex > 0"
                        :icon="
                          direction === 'rtl'
                            ? 'i-lucide-chevron-right'
                            : 'i-lucide-chevron-left'
                        "
                        color="slate"
                        size="sm"
                        class="absolute z-10 -translate-y-1/2 rounded-full shadow-md top-1/2 start-1"
                        :aria-label="
                          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.PREVIOUS_CARD')
                        "
                        @click="navigateCard(-1)"
                      />
                      <Button
                        v-if="activeCardIndex < state.cards.length - 1"
                        :icon="
                          direction === 'rtl'
                            ? 'i-lucide-chevron-left'
                            : 'i-lucide-chevron-right'
                        "
                        color="slate"
                        size="sm"
                        class="absolute z-10 -translate-y-1/2 rounded-full shadow-md top-1/2 end-1"
                        :aria-label="
                          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.NEXT_CARD')
                        "
                        @click="navigateCard(1)"
                      />
                    </div>
                  </div>
                  <div
                    v-else
                    class="self-start max-w-[92%] overflow-hidden rounded-xl rounded-ss-sm bg-white shadow-sm text-xs text-[#111827]"
                  >
                    <div
                      v-if="
                        ['image', 'video', 'document'].includes(
                          state.headerType
                        )
                      "
                      class="flex items-center justify-center h-28 bg-[#e9edef] text-[#8696a0]"
                    >
                      <img
                        v-if="
                          state.headerType === 'image' && state.headerMediaUrl
                        "
                        :src="state.headerMediaUrl"
                        class="object-cover w-full h-full"
                      />
                      <span v-else class="flex flex-col items-center gap-2">
                        <Icon
                          :icon="
                            state.headerType === 'video'
                              ? 'i-lucide-video'
                              : state.headerType === 'document'
                                ? 'i-lucide-file-text'
                                : 'i-lucide-image'
                          "
                          class="size-6"
                        />
                        {{
                          state.headerMediaName ||
                          t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.MEDIA')
                        }}
                      </span>
                    </div>
                    <div class="p-3">
                      <p
                        v-if="state.headerType === 'text' && state.headerText"
                        class="mb-2 text-sm font-semibold"
                      >
                        {{ state.headerText }}
                      </p>
                      <p class="leading-5 whitespace-pre-wrap">
                        {{
                          state.body ||
                          t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY')
                        }}
                      </p>
                      <p
                        v-if="state.footer"
                        class="mt-2 text-[0.65rem] text-[#667781]"
                      >
                        {{ state.footer }}
                      </p>
                      <span
                        class="block mt-1 text-[0.58rem] text-end text-[#8696a0]"
                      >
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
                      </span>
                    </div>
                    <div
                      v-if="state.buttonText"
                      class="px-3 py-2.5 border-t border-[#e9edef] text-center font-medium text-[#00a884]"
                    >
                      {{ state.buttonText }}
                    </div>
                  </div>
                </div>
                <div
                  class="flex items-center gap-2 px-3 py-2.5 border-t border-[#dde2e5] bg-[#f7f9fa] text-[#8696a0]"
                >
                  <Icon icon="i-lucide-plus" class="size-5" />
                  <div
                    class="flex items-center flex-1 gap-2 px-3 py-2 rounded-full bg-[#eef1f3]"
                  >
                    <Icon icon="i-lucide-smile" class="size-4" />
                    <span class="text-[0.65rem] grow">
                      {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.MESSAGE') }}
                    </span>
                    <Icon icon="i-lucide-paperclip" class="size-4" />
                    <Icon icon="i-lucide-camera" class="size-4" />
                  </div>
                  <Icon icon="i-lucide-mic" class="size-5" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </Dialog>
</template>
