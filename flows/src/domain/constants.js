export const PLATFORM_OPTIONS = [
  { id: 'whatsapp', label: 'واتساب', icon: 'i-lucide-message-circle' },
  { id: 'instagram', label: 'إنستغرام', icon: 'i-lucide-instagram' },
  { id: 'messenger', label: 'ماسنجر', icon: 'i-lucide-messages-square' },
];

export const NODE_TYPES = {
  TRIGGER: 'trigger',
  TEXT: 'text',
  IMAGE: 'image',
  VIDEO: 'video',
  DOCUMENT: 'document',
  AUDIO: 'audio',
  INTERACTIVE: 'interactive',
  INTERACTIVE_BUTTON: 'interactive_button',
  INTERACTIVE_LIST: 'interactive_list',
  CONDITION: 'condition',
  LOCATION: 'location',
  LOCATION_REQUEST: 'location_request',
  CONTACT: 'contact',
  STICKER: 'sticker',
  REACTION: 'reaction',
  CTA_URL: 'cta_url',
  CAROUSEL: 'carousel',
};

export const ACTION_NODE_OPTIONS = [
  {
    type: NODE_TYPES.INTERACTIVE,
    label: 'تفاعلي',
    icon: 'i-lucide-list-tree',
    platform: 'whatsapp',
  },
  { type: NODE_TYPES.TEXT, label: 'نص', icon: 'i-lucide-text' },
  { type: NODE_TYPES.IMAGE, label: 'صورة', icon: 'i-lucide-image' },
  { type: NODE_TYPES.VIDEO, label: 'فيديو', icon: 'i-lucide-video' },
  { type: NODE_TYPES.DOCUMENT, label: 'مستند PDF', icon: 'i-lucide-file-text' },
  { type: NODE_TYPES.AUDIO, label: 'صوت', icon: 'i-lucide-audio-lines' },
  { type: NODE_TYPES.CONDITION, label: 'شرط', icon: 'i-lucide-git-branch' },
  {
    type: NODE_TYPES.LOCATION,
    label: 'موقع',
    icon: 'i-lucide-map-pin',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.LOCATION_REQUEST,
    label: 'طلب موقع',
    icon: 'i-lucide-locate-fixed',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.CONTACT,
    label: 'جهة اتصال',
    icon: 'i-lucide-contact',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.STICKER,
    label: 'ملصق',
    icon: 'i-lucide-sticker',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.REACTION,
    label: 'تفاعل',
    icon: 'i-lucide-smile-plus',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.CTA_URL,
    label: 'زر رابط',
    icon: 'i-lucide-external-link',
    platform: 'whatsapp',
  },
  {
    type: NODE_TYPES.CAROUSEL,
    label: 'معرض وسائط',
    icon: 'i-lucide-gallery-horizontal',
    platform: 'whatsapp',
  },
];

export const MATCH_TYPES = [{ id: 'exact', label: 'تطابق تام' }];

export const NO_MATCH_FREQUENCIES = [
  { id: 'always', label: 'طوال الوقت' },
  { id: 'daily', label: 'مرة في اليوم' },
  { id: 'weekly', label: 'مرة في الأسبوع' },
  { id: 'monthly', label: 'مرة في الشهر' },
];
