<script setup lang="ts">
import { Search } from 'lucide-vue-next'

const { placeholder = 'search for ...' } = defineProps<{
  placeholder?: string
  disabled?: boolean
}>()
const q = defineModel({ default: '' })
</script>

<template>
  <div class="flex gap-2 items-center">
    <Label for="q">
      <div class="w-10 h-10 border rounded-full flex-center shrink-0">
        <Search :size="20" />
      </div>
    </Label>
    <Input id="q" v-model="q" :disabled="disabled" :placeholder="placeholder" />
  </div>
</template>
