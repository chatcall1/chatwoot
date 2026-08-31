/* global axios */

import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  analyticsMetrics(id) {
    return axios.get(`${this.url}/${id}/analytics/metrics`);
  }

  analyticsContacts(id, { status, page } = {}) {
    return axios.get(`${this.url}/${id}/analytics/contacts`, {
      params: { status, page },
    });
  }

  testTemplate(payload) {
    return axios.post(`${this.url}/test`, { campaign: payload });
  }

  audienceCount(payload) {
    return axios.post(`${this.url}/audience_count`, { campaign: payload });
  }
}

export default new CampaignsAPI();
