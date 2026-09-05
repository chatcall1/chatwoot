<script setup>
import { useI18n } from 'vue-i18n';
import FileUpload from 'vue-upload-component';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

defineProps({
  visibleSections: { type: Array, required: true },
  selectedSection: { type: String, required: true },
  mediaHeaderTypes: { type: Array, required: true },
  mediaAccept: { type: String, required: true },
  templateFormat: { type: String, required: true },
  catalogBodyMaxLength: { type: Number, required: true },
  bodyVariableIndexes: { type: Array, required: true },
  buttonTypes: { type: Array, required: true },
  flowOptions: { type: Array, required: true },
  isLoadingFlows: { type: Boolean, required: true },
  variableIndexes: { type: Function, required: true },
});
defineEmits([
  'toggleSection',
  'toggleHeaderType',
  'addHeaderVariable',
  'handleHeaderFile',
  'setHeaderGifMode',
  'addBodyVariable',
  'removeButton',
  'fetchFlows',
  'addButton',
]);
const state = defineModel('state', { type: Object, required: true });
const { t } = useI18n();
</script>

<template>
  <div
    v-for="section in visibleSections"
    :key="section.key"
    class="border rounded-xl border-n-strong bg-n-alpha-1"
  >
    <button
      type="button"
      class="flex items-center justify-between w-full gap-3 p-4 text-start"
      @click="$emit('toggleSection', section.key)"
    >
      <span class="flex items-center gap-2 text-sm font-medium text-n-slate-12">
        <Icon
          :icon="
            selectedSection === section.key
              ? 'i-lucide-chevron-up'
              : 'i-lucide-chevron-down'
          "
          class="size-4"
        />
        {{ section.label }}
        <span
          v-if="section.optional"
          class="text-xs font-normal text-n-slate-10"
        >
          {{ t('WHATSAPP_TEMPLATE_BUILDER.OPTIONAL') }}
        </span>
      </span>
    </button>
    <div v-if="selectedSection === section.key" class="p-4 pt-0">
      <template v-if="section.key === 'header'">
        <div
          class="grid grid-cols-2 gap-1 p-1 rounded-lg sm:grid-cols-4 bg-n-alpha-2"
        >
          <Button
            v-for="headerType in mediaHeaderTypes"
            :key="headerType.value"
            :label="headerType.label"
            :variant="state.headerType === headerType.value ? 'solid' : 'ghost'"
            :color="state.headerType === headerType.value ? 'teal' : 'slate'"
            size="sm"
            class="justify-center"
            @click="$emit('toggleHeaderType', headerType.value)"
          />
        </div>
        <div v-if="state.headerType === 'text'" class="grid gap-2 mt-3">
          <Input
            v-model="state.headerText"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TEXT_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TEXT_PLACEHOLDER')
            "
          />
          <div class="flex justify-end">
            <Button
              :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.ADD_VARIABLE')"
              icon="i-lucide-braces"
              color="teal"
              variant="ghost"
              size="sm"
              :disabled="variableIndexes(state.headerText).length > 0"
              @click="$emit('addHeaderVariable')"
            />
          </div>
        </div>
        <Input
          v-if="
            state.headerType === 'text' &&
            variableIndexes(state.headerText).length
          "
          v-model="state.headerExample"
          class="mt-3"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.EXAMPLE_LABEL')"
          :placeholder="
            t('WHATSAPP_TEMPLATE_BUILDER.HEADER.EXAMPLE_PLACEHOLDER')
          "
        />
        <FileUpload
          v-else-if="['image', 'video', 'document'].includes(state.headerType)"
          input-id="whatsappTemplateHeaderMedia"
          :accept="mediaAccept"
          :multiple="false"
          :drop-directory="false"
          class="block mt-3"
          @input-file="file => $emit('handleHeaderFile', file)"
        >
          <div
            class="flex items-center justify-between gap-4 p-4 border border-dashed cursor-pointer rounded-xl border-n-strong bg-n-alpha-1 hover:border-n-brand"
          >
            <span class="flex flex-col gap-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.HEADER.UPLOAD') }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{
                  state.headerMediaName ||
                  t('WHATSAPP_TEMPLATE_BUILDER.HEADER.UPLOAD_HELPER')
                }}
              </span>
            </span>
            <span
              class="grid border rounded-lg size-10 shrink-0 place-items-center border-n-strong bg-n-alpha-3"
            >
              <Icon icon="i-lucide-upload" class="size-5" />
            </span>
          </div>
        </FileUpload>
        <label
          v-if="state.headerType === 'video' && state.category === 'MARKETING'"
          class="flex items-center justify-between gap-3 p-3 mt-3 border rounded-lg cursor-pointer border-n-strong"
        >
          <span>
            <span class="block text-sm font-medium text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.GIF_MODE') }}
            </span>
            <span class="block mt-1 text-xs text-n-slate-10">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.GIF_MODE_HELPER') }}
            </span>
          </span>
          <Switch
            :model-value="state.headerGifEnabled"
            @update:model-value="value => $emit('setHeaderGifMode', value)"
          />
        </label>
      </template>
      <div v-else-if="section.key === 'body'" class="grid gap-3">
        <Editor
          v-model="state.body"
          :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.BODY.PLACEHOLDER')"
          :max-length="
            templateFormat === 'catalog' ? catalogBodyMaxLength : 1024
          "
          channel-type="Context::WhatsappTemplate"
        >
          <template #actions>
            <div class="flex items-center justify-between w-full">
              <span class="text-xs tabular-nums text-n-slate-10">
                {{
                  t('WHATSAPP_TEMPLATE_BUILDER.BODY.CHARACTER_COUNT', {
                    current: state.body.length,
                    max:
                      templateFormat === 'catalog'
                        ? catalogBodyMaxLength
                        : 1024,
                  })
                }}
              </span>
              <Button
                :label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_VARIABLE')"
                icon="i-lucide-braces"
                color="teal"
                variant="ghost"
                size="sm"
                @click="$emit('addBodyVariable')"
              />
            </div>
          </template>
        </Editor>
        <div
          v-if="bodyVariableIndexes.length"
          class="grid gap-3 sm:grid-cols-2"
        >
          <Input
            v-for="index in bodyVariableIndexes"
            :key="index"
            v-model="state.bodyExamples[index]"
            :label="
              t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE', {
                n: index,
              })
            "
            :placeholder="
              t(
                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE_PLACEHOLDER'
              )
            "
          />
        </div>
      </div>
      <Input
        v-else-if="section.key === 'footer'"
        v-model="state.footer"
        :maxlength="60"
        :label="t('WHATSAPP_TEMPLATE_BUILDER.FOOTER.LABEL')"
        :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.FOOTER.PLACEHOLDER')"
      />
      <div v-else class="grid gap-3">
        <div
          v-for="(button, index) in state.standardButtons"
          :key="button.id"
          class="grid gap-3 p-3 border rounded-xl border-n-strong bg-n-alpha-2"
        >
          <div class="flex items-center gap-2">
            <ComboBox
              v-model="button.type"
              class="grow"
              :options="buttonTypes"
              :placeholder="
                t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPE_PLACEHOLDER')
              "
            />
            <Button
              icon="i-lucide-trash-2"
              color="slate"
              variant="ghost"
              @click="$emit('removeButton', index)"
            />
          </div>
          <Input
            v-if="button.type !== 'COPY_CODE'"
            v-model="button.text"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_PLACEHOLDER')
            "
          />
          <Input
            v-if="button.type === 'COPY_CODE'"
            v-model="button.example"
            maxlength="20"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.COPY_CODE_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.COPY_CODE_PLACEHOLDER')
            "
          />
          <Input
            v-if="button.type === 'URL'"
            v-model="button.value"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.URL_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.URL_PLACEHOLDER')
            "
          />
          <label
            v-if="button.type === 'URL' && state.category === 'MARKETING'"
            class="flex items-center justify-between gap-3 cursor-pointer"
          >
            <span>
              <span class="block text-sm font-medium text-n-slate-12">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.DEEP_LINK') }}
              </span>
              <span class="block mt-1 text-xs text-n-slate-10">
                {{
                  t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.DEEP_LINK_HELPER')
                }}
              </span>
            </span>
            <Switch v-model="button.deepLinkEnabled" />
          </label>
          <div
            v-if="button.type === 'URL' && button.deepLinkEnabled"
            class="grid gap-3 md:grid-cols-2"
          >
            <Input
              v-model="button.metaAppId"
              :label="t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.META_APP_ID')"
            />
            <Input
              v-model="button.androidDeepLink"
              :label="
                t('WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.ANDROID_DEEP_LINK')
              "
            />
            <Input
              v-model="button.androidFallbackUrl"
              class="md:col-span-2"
              :label="
                t(
                  'WHATSAPP_TEMPLATE_BUILDER.MARKETING_API.ANDROID_FALLBACK_URL'
                )
              "
            />
          </div>
          <Input
            v-if="button.type === 'URL' && variableIndexes(button.value).length"
            v-model="button.example"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.URL_EXAMPLE_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.URL_EXAMPLE_PLACEHOLDER')
            "
          />
          <Input
            v-if="button.type === 'PHONE_NUMBER'"
            v-model="button.value"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.PHONE_LABEL')"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.PHONE_PLACEHOLDER')
            "
          />
          <div v-if="button.type === 'FLOW'" class="grid gap-2">
            <p class="text-sm font-medium text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_LABEL') }}
            </p>
            <div class="flex items-end gap-2">
              <ComboBox
                v-model="button.flowId"
                class="grow"
                :options="flowOptions"
                :placeholder="
                  t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_PLACEHOLDER')
                "
              />
              <Button
                :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FETCH_FLOWS')"
                icon="i-lucide-refresh-cw"
                color="slate"
                variant="outline"
                :is-loading="isLoadingFlows"
                @click="$emit('fetchFlows')"
              />
            </div>
            <p class="text-xs text-n-slate-10">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.FLOW_HELPER') }}
            </p>
          </div>
        </div>
        <Button
          :label="t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.ADD')"
          icon="i-lucide-plus"
          color="slate"
          variant="outline"
          :disabled="state.standardButtons.length >= 10"
          @click="$emit('addButton')"
        />
      </div>
    </div>
  </div>
</template>
