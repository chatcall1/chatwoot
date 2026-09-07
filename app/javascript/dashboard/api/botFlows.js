/* global axios */

import ApiClient from './ApiClient';

class BotFlowsAPI extends ApiClient {
  constructor() {
    super('bot_flows', { accountScoped: true });
  }

  publish(id) {
    return axios.post(`${this.url}/${id}/publish`);
  }

  unpublish(id) {
    return axios.post(`${this.url}/${id}/unpublish`);
  }

  executions(id) {
    return axios.get(`${this.url}/${id}/executions`);
  }

  retryDelivery(id, deliveryId) {
    return axios.post(`${this.url}/${id}/retry_delivery`, {
      delivery_id: deliveryId,
    });
  }
}

export default new BotFlowsAPI();
