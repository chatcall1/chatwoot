<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import { generateId } from '../../utils/id';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const labels = {
  formattedName: 'الاسم المعروض',
  firstName: 'الاسم الأول',
  lastName: 'اسم العائلة',
  birthday: 'تاريخ الميلاد',
  company: 'الشركة',
  jobTitle: 'المسمى الوظيفي',
  phones: 'أرقام الهاتف',
  phone: 'رقم الهاتف',
  waId: 'معرّف واتساب',
  emails: 'البريد الإلكتروني',
  email: 'البريد',
  urls: 'المواقع الإلكترونية',
  url: 'الرابط',
  address: 'العنوان',
  street: 'الشارع',
  city: 'المدينة',
  state: 'المنطقة',
  zip: 'الرمز البريدي',
  country: 'الدولة',
  add: 'إضافة',
  remove: 'حذف',
};
const patch = changes => emit('update', { ...props.data, ...changes });
const patchName = changes =>
  patch({ name: { ...props.data.name, ...changes } });
const patchOrg = changes => patch({ org: { ...props.data.org, ...changes } });
const updateItem = (key, index, changes) => {
  const items = props.data[key].map((item, itemIndex) =>
    itemIndex === index ? { ...item, ...changes } : item
  );
  patch({ [key]: items });
};
const addItem = (key, value) =>
  patch({ [key]: [...props.data[key], { id: generateId(), ...value }] });
const removeItem = (key, index) =>
  patch({
    [key]: props.data[key].filter((_, itemIndex) => itemIndex !== index),
  });
</script>

<template>
  <Input
    :model-value="data.name.formatted_name"
    :label="labels.formattedName"
    @update:model-value="patchName({ formatted_name: $event })"
  />
  <div class="grid grid-cols-2 gap-3">
    <Input
      :model-value="data.name.first_name"
      :label="labels.firstName"
      @update:model-value="patchName({ first_name: $event })"
    />
    <Input
      :model-value="data.name.last_name"
      :label="labels.lastName"
      @update:model-value="patchName({ last_name: $event })"
    />
  </div>
  <Input
    :model-value="data.birthday"
    type="date"
    :label="labels.birthday"
    @update:model-value="patch({ birthday: $event })"
  />
  <div class="grid grid-cols-2 gap-3">
    <Input
      :model-value="data.org.company"
      :label="labels.company"
      @update:model-value="patchOrg({ company: $event })"
    />
    <Input
      :model-value="data.org.title"
      :label="labels.jobTitle"
      @update:model-value="patchOrg({ title: $event })"
    />
  </div>

  <section class="space-y-2">
    <div class="flex items-center justify-between">
      <span class="flow-label">{{ labels.phones }}</span>
      <button
        class="flow-icon-btn"
        type="button"
        :title="labels.add"
        @click="addItem('phones', { phone: '', type: 'CELL', wa_id: '' })"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>
    <div
      v-for="(phone, index) in data.phones"
      :key="phone.id"
      class="space-y-2 rounded-lg border border-n-weak p-3"
    >
      <div class="flex gap-2">
        <Input
          class="flex-1"
          :model-value="phone.phone"
          :label="labels.phone"
          @update:model-value="updateItem('phones', index, { phone: $event })"
        /><button
          class="flow-icon-btn mt-6"
          type="button"
          :title="labels.remove"
          @click="removeItem('phones', index)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </div>
      <Input
        :model-value="phone.wa_id"
        :label="labels.waId"
        @update:model-value="updateItem('phones', index, { wa_id: $event })"
      />
    </div>
  </section>

  <section class="space-y-2">
    <div class="flex items-center justify-between">
      <span class="flow-label">{{ labels.emails }}</span>
      <button
        class="flow-icon-btn"
        type="button"
        :title="labels.add"
        @click="addItem('emails', { email: '', type: 'WORK' })"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>
    <div
      v-for="(email, index) in data.emails"
      :key="email.id"
      class="flex gap-2 rounded-lg border border-n-weak p-3"
    >
      <Input
        class="flex-1"
        :model-value="email.email"
        type="email"
        :label="labels.email"
        @update:model-value="updateItem('emails', index, { email: $event })"
      /><button
        class="flow-icon-btn mt-6"
        type="button"
        :title="labels.remove"
        @click="removeItem('emails', index)"
      >
        <span class="i-lucide-trash-2 size-4" />
      </button>
    </div>
  </section>

  <section class="space-y-2">
    <div class="flex items-center justify-between">
      <span class="flow-label">{{ labels.urls }}</span>
      <button
        class="flow-icon-btn"
        type="button"
        :title="labels.add"
        @click="addItem('urls', { url: '', type: 'WORK' })"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>
    <div
      v-for="(url, index) in data.urls"
      :key="url.id"
      class="flex gap-2 rounded-lg border border-n-weak p-3"
    >
      <Input
        class="flex-1"
        :model-value="url.url"
        type="url"
        :label="labels.url"
        @update:model-value="updateItem('urls', index, { url: $event })"
      /><button
        class="flow-icon-btn mt-6"
        type="button"
        :title="labels.remove"
        @click="removeItem('urls', index)"
      >
        <span class="i-lucide-trash-2 size-4" />
      </button>
    </div>
  </section>

  <section class="space-y-2">
    <div class="flex items-center justify-between">
      <span class="flow-label">{{ labels.address }}</span>
      <button
        class="flow-icon-btn"
        type="button"
        :title="labels.add"
        @click="
          addItem('addresses', {
            street: '',
            city: '',
            state: '',
            zip: '',
            country: '',
            country_code: '',
            type: 'WORK',
          })
        "
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>
    <div
      v-for="(address, index) in data.addresses"
      :key="address.id"
      class="space-y-2 rounded-lg border border-n-weak p-3"
    >
      <div class="flex gap-2">
        <Input
          class="flex-1"
          :model-value="address.street"
          :label="labels.street"
          @update:model-value="
            updateItem('addresses', index, { street: $event })
          "
        /><button
          class="flow-icon-btn mt-6"
          type="button"
          :title="labels.remove"
          @click="removeItem('addresses', index)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </div>
      <div class="grid grid-cols-2 gap-2">
        <Input
          :model-value="address.city"
          :label="labels.city"
          @update:model-value="updateItem('addresses', index, { city: $event })"
        /><Input
          :model-value="address.state"
          :label="labels.state"
          @update:model-value="
            updateItem('addresses', index, { state: $event })
          "
        /><Input
          :model-value="address.zip"
          :label="labels.zip"
          @update:model-value="updateItem('addresses', index, { zip: $event })"
        /><Input
          :model-value="address.country"
          :label="labels.country"
          @update:model-value="
            updateItem('addresses', index, { country: $event })
          "
        />
      </div>
    </div>
  </section>
</template>
