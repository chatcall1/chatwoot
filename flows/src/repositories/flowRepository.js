import { generateId } from '../utils/id';
import { cloneJson } from '../utils/json';

const accountId = () =>
  window.location.pathname.match(/\/accounts\/(\d+)/)?.[1] || 'unknown';
const storageKey = () => `chatwoot.flow-builder.v1.account.${accountId()}`;

const read = () => {
  try {
    const value = JSON.parse(localStorage.getItem(storageKey()) || '[]');
    return Array.isArray(value) ? value : [];
  } catch {
    return [];
  }
};

const write = flows =>
  localStorage.setItem(storageKey(), JSON.stringify(flows));

export const flowRepository = {
  list() {
    return read().sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  },

  save(flow) {
    const flows = read();
    const index = flows.findIndex(item => item.id === flow.id);
    const record = cloneJson({
      ...flow,
      updatedAt: new Date().toISOString(),
    });
    if (index === -1) flows.push(record);
    else flows[index] = record;
    write(flows);
    return record;
  },

  remove(id) {
    write(read().filter(flow => flow.id !== id));
  },

  import(rawFlow) {
    const requiredKeys = ['id', 'reference', 'name', 'platforms', 'graph'];
    if (!rawFlow || requiredKeys.some(key => !(key in rawFlow))) {
      throw new Error('ملف JSON لا يحتوي على بنية بوت صالحة.');
    }
    if (
      !Array.isArray(rawFlow.graph.nodes) ||
      !Array.isArray(rawFlow.graph.edges)
    ) {
      throw new Error('بيانات العقد والروابط غير صالحة.');
    }
    const imported = cloneJson(rawFlow);
    imported.id = generateId();
    imported.reference = `BOT-${generateId().slice(0, 8).toUpperCase()}`;
    imported.status = 'draft';
    imported.createdAt = new Date().toISOString();
    return this.save(imported);
  },
};
