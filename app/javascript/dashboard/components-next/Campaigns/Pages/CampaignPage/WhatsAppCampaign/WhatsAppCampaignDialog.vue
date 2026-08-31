<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import WhatsAppCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const discardDialogRef = ref(null);
const isDirty = ref(false);

const close = () => {
  dialogRef.value?.close();
  emit('close');
};

const requestClose = () => {
  if (isDirty.value) {
    discardDialogRef.value?.open();
    return;
  }
  close();
};

const confirmDiscard = () => {
  discardDialogRef.value?.close();
  close();
};

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });

    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.SUCCESS_MESSAGE'));
    isDirty.value = false;
    close();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.WHATSAPP.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

onMounted(() => dialogRef.value?.open());
</script>

<template>
  <Dialog
    ref="dialogRef"
    persistent
    overflow-y-auto
    width="6xl"
    :show-cancel-button="false"
    :show-confirm-button="false"
    :title="t('CAMPAIGN.WHATSAPP.CREATE.TITLE')"
  >
    <WhatsAppCampaignForm
      @submit="addCampaign"
      @cancel="requestClose"
      @update:dirty="isDirty = $event"
    />
  </Dialog>

  <Dialog
    ref="discardDialogRef"
    type="alert"
    :title="t('CAMPAIGN.WHATSAPP.CREATE.DISCARD.TITLE')"
    :description="t('CAMPAIGN.WHATSAPP.CREATE.DISCARD.DESCRIPTION')"
    :confirm-button-label="t('CAMPAIGN.WHATSAPP.CREATE.DISCARD.CONFIRM')"
    @confirm="confirmDiscard"
  />
</template>
