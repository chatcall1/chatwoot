<script setup>
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

defineProps({
  authenticationOtpTypes: { type: Array, required: true },
});
defineEmits(['addApp', 'removeApp']);
const state = defineModel('state', { type: Object, required: true });
const { t } = useI18n();
</script>

<template>
  <section
    class="grid gap-5 p-5 border-2 rounded-xl border-n-slate-8 bg-n-alpha-1"
  >
    <div
      class="flex items-start gap-3 p-3 rounded-lg bg-n-blue-2 text-n-blue-12"
    >
      <Icon icon="i-lucide-shield-check" class="mt-0.5 size-5 shrink-0" />
      <p class="text-xs leading-5">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PRESET_HELPER') }}
      </p>
    </div>
    <div class="grid gap-3">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.DELIVERY_TYPE') }}
      </h3>
      <div class="grid gap-3 md:grid-cols-3">
        <button
          v-for="type in authenticationOtpTypes"
          :key="type.value"
          type="button"
          class="flex items-start gap-3 p-3 text-start border-2 rounded-xl transition-colors"
          :class="
            state.authenticationOtpType === type.value
              ? 'border-n-brand bg-n-brand/5'
              : 'border-n-slate-8 hover:border-n-slate-10'
          "
          @click="state.authenticationOtpType = type.value"
        >
          <Icon :icon="type.icon" class="mt-0.5 size-5 shrink-0 text-n-brand" />
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
    </div>
    <div class="grid gap-3 p-4 border rounded-xl border-n-slate-8">
      <label class="flex items-center justify-between gap-3 cursor-pointer">
        <span>
          <span class="block text-sm font-medium text-n-slate-12">{{
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.SECURITY')
          }}</span>
          <span class="block mt-1 text-xs text-n-slate-10">{{
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.SECURITY_HELPER')
          }}</span>
        </span>
        <Switch v-model="state.authenticationSecurityRecommendation" />
      </label>
      <div class="grid gap-3 pt-3 border-t border-n-weak md:grid-cols-2">
        <label class="flex items-center justify-between gap-3 cursor-pointer">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.EXPIRATION')
          }}</span>
          <Switch v-model="state.authenticationExpirationEnabled" />
        </label>
        <Input
          v-if="state.authenticationExpirationEnabled"
          v-model="state.authenticationCodeExpirationMinutes"
          type="number"
          min="1"
          max="90"
          :label="
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.EXPIRATION_MINUTES')
          "
        />
        <label class="flex items-center justify-between gap-3 cursor-pointer">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TTL')
          }}</span>
          <Switch v-model="state.authenticationTtlEnabled" />
        </label>
        <Input
          v-if="state.authenticationTtlEnabled"
          v-model="state.authenticationTtlSeconds"
          type="number"
          min="1"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.TTL_SECONDS')"
        />
      </div>
    </div>
    <div class="grid gap-3 md:grid-cols-2">
      <Input
        v-model="state.authenticationCopyCodeText"
        maxlength="25"
        :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.COPY_TEXT')"
        :placeholder="
          t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.LOCALIZED_DEFAULT')
        "
      />
      <Input
        v-if="state.authenticationOtpType !== 'COPY_CODE'"
        v-model="state.authenticationAutofillText"
        maxlength="25"
        :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.AUTOFILL_TEXT')"
        :placeholder="
          t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.LOCALIZED_DEFAULT')
        "
      />
    </div>
    <div
      v-if="state.authenticationOtpType !== 'COPY_CODE'"
      class="grid gap-3 p-4 border rounded-xl border-n-slate-8"
    >
      <div class="flex items-center justify-between gap-3">
        <span>
          <span class="block text-sm font-semibold text-n-slate-12">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.APPS') }}
          </span>
          <span class="block mt-1 text-xs text-n-slate-10">{{
            t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.APPS_HELPER')
          }}</span>
        </span>
        <Button
          :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.ADD_APP')"
          icon="i-lucide-plus"
          size="sm"
          color="slate"
          variant="outline"
          @click="$emit('addApp')"
        />
      </div>
      <div
        v-for="(app, index) in state.authenticationApps"
        :key="app.id"
        class="grid gap-3 p-3 border rounded-lg border-n-slate-8 md:grid-cols-[1fr_1fr_auto]"
      >
        <Input
          v-model="app.packageName"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.PACKAGE_NAME')"
          placeholder="com.example.app"
          dir="ltr"
        />
        <Input
          v-model="app.signatureHash"
          maxlength="11"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.SIGNATURE_HASH')"
          placeholder="K8a/AINcGX7"
          dir="ltr"
        />
        <Button
          icon="i-lucide-trash-2"
          color="slate"
          variant="ghost"
          class="self-end"
          :disabled="state.authenticationApps.length === 1"
          :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.REMOVE_APP')"
          @click="$emit('removeApp', index)"
        />
      </div>
    </div>
    <label
      v-if="state.authenticationOtpType === 'ZERO_TAP'"
      class="flex items-start gap-3 p-4 border rounded-xl cursor-pointer border-n-slate-8"
    >
      <Checkbox v-model="state.authenticationTermsAccepted" class="mt-0.5" />
      <span class="text-xs leading-5 text-n-slate-11">{{
        t('WHATSAPP_TEMPLATE_BUILDER.AUTHENTICATION.ZERO_TAP_TERMS')
      }}</span>
    </label>
  </section>
</template>
