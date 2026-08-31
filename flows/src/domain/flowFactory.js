import { NODE_TYPES } from './constants';
import { generateId } from '../utils/id';
import { cloneJson } from '../utils/json';

const randomToken = () => generateId();

export const createFlow = ({ name, platforms, inboxIds, triggerMode }) => {
  const now = new Date().toISOString();
  const triggerId = randomToken();

  return {
    id: randomToken(),
    reference: `BOT-${randomToken().slice(0, 8).toUpperCase()}`,
    name: name.trim(),
    status: 'draft',
    platforms: [...platforms],
    inboxIds: [...inboxIds],
    createdAt: now,
    updatedAt: now,
    graph: {
      nodes: [
        {
          id: triggerId,
          type: NODE_TYPES.TRIGGER,
          position: { x: 80, y: 180 },
          data: {
            label: 'بداية المحادثة',
            mode: triggerMode,
            matchType: 'exact',
            keywords: [],
          },
        },
      ],
      edges: [],
    },
  };
};

export const duplicateFlow = flow => {
  const copy = cloneJson(flow);
  const now = new Date().toISOString();
  copy.id = randomToken();
  copy.reference = `BOT-${randomToken().slice(0, 8).toUpperCase()}`;
  copy.name = `نسخة من ${flow.name}`;
  copy.status = 'draft';
  copy.createdAt = now;
  copy.updatedAt = now;
  return copy;
};

export const createActionNode = (type, index) => ({
  id: randomToken(),
  type,
  position: { x: 390 + index * 30, y: 150 + index * 90 },
  data:
    type === NODE_TYPES.INTERACTIVE
      ? {
          headerType: 'none',
          headerText: '',
          headerUrl: '',
          filename: '',
          body: '',
          footer: '',
        }
      : {
          label: '',
          content: '',
          url: '',
          caption: '',
          filename: '',
        },
});

export const createInteractiveChildNode = (type, position, index = 0) => ({
  id: randomToken(),
  type,
  position: { x: position.x, y: position.y + index * 36 },
  data:
    type === NODE_TYPES.INTERACTIVE_BUTTON
      ? { title: `زر ${index + 1}` }
      : {
          buttonText: 'عرض القائمة',
          body: '',
          rows: [{ id: generateId(), title: 'الخيار الأول' }],
        },
});
