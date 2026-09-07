import BotFlowsAPI from 'dashboard/api/botFlows';
import { cloneJson } from '../utils/json';

const payloadFor = flow => ({
  bot_flow: {
    name: flow.name,
    inbox_id: flow.inboxIds[0],
    lock_version: flow.lockVersion,
    draft_definition: cloneJson(flow.graph),
  },
});

export const flowRepository = {
  async list() {
    const { data } = await BotFlowsAPI.get();
    return data;
  },

  async save(flow) {
    const response = flow.id
      ? await BotFlowsAPI.update(flow.id, payloadFor(flow))
      : await BotFlowsAPI.create(payloadFor(flow));
    return response.data;
  },

  async remove(id) {
    await BotFlowsAPI.delete(id);
  },

  async import(rawFlow) {
    if (
      !rawFlow?.name ||
      !Array.isArray(rawFlow.inboxIds) ||
      !Array.isArray(rawFlow.graph?.nodes) ||
      !Array.isArray(rawFlow.graph?.edges)
    ) {
      throw new Error('ملف JSON لا يحتوي على بنية بوت صالحة.');
    }

    return this.save({
      ...cloneJson(rawFlow),
      id: null,
      reference: null,
      status: 'draft',
    });
  },

  async publish(id) {
    const { data } = await BotFlowsAPI.publish(id);
    return data;
  },

  async unpublish(id) {
    const { data } = await BotFlowsAPI.unpublish(id);
    return data;
  },

  async executions(id) {
    const { data } = await BotFlowsAPI.executions(id);
    return data;
  },

  async retryDelivery(id, deliveryId) {
    await BotFlowsAPI.retryDelivery(id, deliveryId);
  },
};
