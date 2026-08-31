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
  INTERACTIVE: 'interactive',
  INTERACTIVE_BUTTON: 'interactive_button',
  INTERACTIVE_LIST: 'interactive_list',
};

export const ACTION_NODE_OPTIONS = [
  { type: NODE_TYPES.TEXT, label: 'نص', icon: 'i-lucide-text' },
  { type: NODE_TYPES.IMAGE, label: 'صورة', icon: 'i-lucide-image' },
  { type: NODE_TYPES.VIDEO, label: 'فيديو', icon: 'i-lucide-video' },
  { type: NODE_TYPES.DOCUMENT, label: 'مستند PDF', icon: 'i-lucide-file-text' },
  {
    type: NODE_TYPES.INTERACTIVE,
    label: 'تفاعلي',
    icon: 'i-lucide-list-tree',
    platform: 'whatsapp',
  },
];

export const MATCH_TYPES = [
  { id: 'exact', label: 'تطابق تام' },
  { id: 'contains', label: 'يحتوي على' },
];
