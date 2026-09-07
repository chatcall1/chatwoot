import { NODE_TYPES } from './constants';
import { generateId } from '../utils/id';
import { cloneJson } from '../utils/json';

const randomToken = () => generateId();

const node = (id, type, x, y, data) => ({
  id,
  type,
  position: { x, y },
  data,
});

const edge = (source, target, sourceHandle = 'next') => ({
  id: `edge-${randomToken()}`,
  type: 'flow',
  source,
  target,
  sourceHandle,
  targetHandle: null,
});

const templateGraph = templateId => {
  const triggerId = randomToken();
  const triggerMode = templateId.startsWith('welcome_')
    ? 'no_match'
    : 'exact_match';
  const keywordsByTemplate = {
    exact_hours: ['ساعات العمل', 'الدوام'],
    exact_prices: ['الأسعار', 'الباقات'],
    exact_order: ['حالة الطلب', 'تتبع الطلب'],
    exact_support: ['الدعم', 'خدمة العملاء'],
  };
  const trigger = node(triggerId, NODE_TYPES.TRIGGER, 380, 80, {
    label: triggerMode === 'no_match' ? 'رسالة الترحيب' : 'تطابق الكلمة',
    mode: triggerMode,
    matchType: 'exact',
    keywords: keywordsByTemplate[templateId] || [],
    capture: 'first_word',
    noMatchFrequency: 'always',
  });

  if (templateId === 'welcome_buttons') {
    const interactiveId = randomToken();
    const choices = [
      [
        'استعراض الخدمات',
        'يسعدنا مساعدتك. اختر الخدمة التي تريد معرفتها من القائمة المتاحة.',
      ],
      [
        'التحدث مع الدعم',
        'تم استلام طلبك. سيتولى أحد أعضاء فريق الدعم متابعة المحادثة.',
      ],
      ['مواعيد العمل', 'نعمل يوميًا من الساعة 9 صباحًا حتى 6 مساءً.'],
    ];
    const nodes = [
      trigger,
      node(interactiveId, NODE_TYPES.INTERACTIVE, 380, 290, {
        interactionType: 'buttons',
        headerType: 'image',
        headerText: '',
        headerBlobSignedId: '',
        headerFilename: '',
        headerContentType: '',
        headerByteSize: 0,
        templateAsset: 'demo_company_logo',
        body: 'مرحبًا بك في شركة آفاق للخدمات. كيف يمكننا مساعدتك اليوم؟',
        footer: 'اختر أحد الخيارات للمتابعة',
      }),
    ];
    const edges = [edge(triggerId, interactiveId)];
    choices.forEach(([title, content], index) => {
      const buttonId = randomToken();
      const responseId = randomToken();
      nodes.push(
        node(buttonId, NODE_TYPES.INTERACTIVE_BUTTON, 120 + index * 270, 520, {
          title,
          replyId: `welcome-option-${index + 1}`,
        }),
        node(responseId, NODE_TYPES.TEXT, 120 + index * 270, 750, { content })
      );
      edges.push(
        edge(interactiveId, buttonId, 'buttons'),
        edge(buttonId, responseId)
      );
    });
    return { nodes, edges };
  }

  if (templateId === 'welcome_list') {
    const interactiveId = randomToken();
    const listId = randomToken();
    const rows = [
      [
        'خدماتنا',
        'تعرّف على الخدمات المتاحة',
        'نقدم حلولًا متكاملة يمكن تخصيصها وفق احتياجك.',
      ],
      [
        'الأسعار والباقات',
        'استعرض خيارات الاشتراك',
        'تتوفر عدة باقات مرنة. أخبرنا باحتياجك لنرشح الأنسب.',
      ],
      [
        'حالة الطلب',
        'متابعة طلب قائم',
        'أرسل رقم الطلب وسنساعدك في معرفة حالته.',
      ],
      [
        'مواعيد العمل',
        'أوقات استقبال الطلبات',
        'نعمل يوميًا من الساعة 9 صباحًا حتى 6 مساءً.',
      ],
      [
        'الفروع والموقع',
        'اعرف أقرب فرع',
        'أرسل مدينتك لنشارك معك أقرب موقع متاح.',
      ],
      [
        'الدعم الفني',
        'الحصول على مساعدة',
        'صف المشكلة باختصار وسيتم توجيهها إلى الدعم.',
      ],
      [
        'الاسترجاع',
        'سياسة الإلغاء والاسترجاع',
        'سنساعدك بعد تزويدنا برقم الطلب وسبب الاسترجاع.',
      ],
      [
        'التحدث مع موظف',
        'تحويل المحادثة للفريق',
        'تم تسجيل طلبك وسيتابع معك أحد أعضاء الفريق.',
      ],
    ].map(([title, description, response]) => ({
      id: randomToken(),
      title,
      description,
      response,
    }));
    const nodes = [
      trigger,
      node(interactiveId, NODE_TYPES.INTERACTIVE, 380, 290, {
        interactionType: 'list',
        headerType: 'text',
        headerText: 'شركة آفاق للخدمات',
        body: 'مرحبًا بك. اختر الموضوع الذي ترغب في المساعدة بشأنه.',
        footer: 'يمكنك اختيار موضوع واحد من القائمة',
      }),
      node(listId, NODE_TYPES.INTERACTIVE_LIST, 380, 510, {
        buttonText: 'عرض الخيارات',
        sections: [
          {
            id: randomToken(),
            title: 'كيف يمكننا مساعدتك؟',
            rows: rows.map(({ response, ...row }) => row),
          },
        ],
      }),
    ];
    const edges = [
      edge(triggerId, interactiveId),
      edge(interactiveId, listId, 'list'),
    ];
    rows.forEach((row, index) => {
      const responseId = randomToken();
      nodes.push(
        node(
          responseId,
          NODE_TYPES.TEXT,
          80 + (index % 4) * 250,
          800 + Math.floor(index / 4) * 220,
          { content: row.response }
        )
      );
      edges.push(edge(listId, responseId, `row:${row.id}`));
    });
    return { nodes, edges };
  }

  const responseId = randomToken();
  const responses = {
    exact_hours: 'نعمل يوميًا من الساعة 9 صباحًا حتى 6 مساءً.',
    exact_prices:
      'لدينا باقات مرنة تناسب احتياجات مختلفة. أخبرنا بالخدمة المطلوبة.',
    exact_order: 'أرسل رقم الطلب وسنساعدك في معرفة حالته.',
    exact_support: 'صف استفسارك باختصار وسيتابع معك فريق الدعم.',
  };
  return {
    nodes: [
      trigger,
      node(responseId, NODE_TYPES.TEXT, 380, 320, {
        content: responses[templateId] || '',
      }),
    ],
    edges: [edge(triggerId, responseId)],
  };
};

export const createFlow = ({ name, platforms, inboxIds, templateId }) => {
  const now = new Date().toISOString();

  return {
    id: null,
    reference: null,
    name: name.trim(),
    status: 'draft',
    platforms: [...platforms],
    inboxIds: [...inboxIds],
    createdAt: now,
    updatedAt: now,
    graph: templateGraph(templateId || 'exact_support'),
  };
};

export const duplicateFlow = flow => {
  const copy = cloneJson(flow);
  const now = new Date().toISOString();
  copy.id = null;
  copy.reference = null;
  copy.name = `نسخة من ${flow.name}`;
  copy.status = 'draft';
  copy.createdAt = now;
  copy.updatedAt = now;
  return copy;
};

const createActionData = type => {
  if (type === NODE_TYPES.CONDITION) {
    return { source: 'incoming_message', operator: 'equals', value: '' };
  }
  if (type === NODE_TYPES.INTERACTIVE) {
    return {
      interactionType: null,
      headerType: 'none',
      headerText: '',
      headerBlobSignedId: '',
      headerFilename: '',
      headerContentType: '',
      headerByteSize: 0,
      filename: '',
      body: '',
      footer: '',
    };
  }
  if (type === NODE_TYPES.LOCATION) {
    return { latitude: '', longitude: '', name: '', address: '' };
  }
  if (type === NODE_TYPES.LOCATION_REQUEST) return { body: '' };
  if (type === NODE_TYPES.REACTION) return { emoji: '👍' };
  if (type === NODE_TYPES.STICKER) {
    return {
      blobSignedId: '',
      filename: '',
      contentType: '',
      byteSize: 0,
      animated: false,
    };
  }
  if (type === NODE_TYPES.CONTACT) {
    return {
      name: {
        formatted_name: '',
        first_name: '',
        middle_name: '',
        last_name: '',
        prefix: '',
        suffix: '',
      },
      birthday: '',
      org: { company: '', department: '', title: '' },
      phones: [{ id: generateId(), phone: '', type: 'CELL', wa_id: '' }],
      emails: [],
      urls: [],
      addresses: [],
    };
  }
  if (type === NODE_TYPES.CTA_URL) {
    return {
      body: '',
      buttonText: '',
      url: '',
      footer: '',
      headerType: 'none',
      headerText: '',
      headerBlobSignedId: '',
      headerFilename: '',
      headerContentType: '',
      headerByteSize: 0,
    };
  }
  if (type === NODE_TYPES.CAROUSEL) {
    return {
      body: '',
      buttonType: 'url',
      cards: [0, 1].map(() => ({
        id: generateId(),
        headerType: 'image',
        blobSignedId: '',
        filename: '',
        contentType: '',
        byteSize: 0,
        body: '',
        buttonText: '',
        url: '',
        replies: [{ id: generateId(), title: '' }],
      })),
    };
  }
  return {
    label: '',
    content: '',
    url: '',
    caption: '',
    filename: '',
    blobSignedId: '',
    contentType: '',
    byteSize: 0,
    isVoiceMessage: false,
  };
};

export const createActionNode = (type, index) => ({
  id: randomToken(),
  type,
  position: { x: 380, y: 300 + index * 190 },
  data: createActionData(type),
});

export const createInteractiveChildNode = (type, position, index = 0) => ({
  id: randomToken(),
  type,
  position: { x: position.x + index * 220, y: position.y },
  data:
    type === NODE_TYPES.INTERACTIVE_BUTTON
      ? { replyId: generateId(), title: `زر ${index + 1}` }
      : {
          buttonText: 'عرض القائمة',
          body: '',
          sections: [
            {
              id: generateId(),
              title: 'الخيارات',
              rows: [
                {
                  id: generateId(),
                  title: 'الخيار الأول',
                  description: '',
                },
              ],
            },
          ],
        },
});
