<script setup lang="ts">
import { Link, Moon, Sun } from 'lucide-vue-next'
import type { RouteNamedMap } from 'vue-router/auto/routes'

const isDark = useDark()
const isEthereum = !!window.ethereum
const store = useStore()
const navs
 = computed<{ to: keyof RouteNamedMap, label: string }[]>(
   () => isEthereum && store.isConnected
     ? [
         { to: '/', label: 'jobs' },
         { to: '/users', label: 'users' },
         { to: '/chats', label: 'chats' },
         { to: '/requests', label: 'requests' },
         { to: '/committees', label: 'committees' },
       ]
     : [],
 )

onMounted(() => {
  store.connect()
})
</script>

<template>
  <nav class="flex items-center justify-between border-b">
    <RouterLink to="/" class="flex items-center gap-2">
      <Link :size="23" class="text-primary" />
      <span class="text-2xl tracking-wide">skillchain</span>
    </RouterLink>

    <ul class="flex items-center justify-between gap-8 text-lg h-[100px] whitespace-nowrap">
      <li v-for="nav in navs" :key="nav.label" class="h-full">
        <RouterLink :to="nav.to" class="flex-center h-full border-b border-transparent hover:border-primary transition-[border]" active-class="border-b-primary">
          {{ nav.label }}
        </RouterLink>
      </li>
    </ul>

    <div class="flex items-center gap-5">
      <button class="block" @click="isDark = !isDark">
        <Moon v-if="isDark" :size="22" />
        <Sun v-else :size="22" />
      </button>
      <template v-if="store.isConnected">
        <div class="flex items-center gap-2.5 text-sm shrink-0">
          <div>
            <p class="text-base text-muted-foreground">
              {{ store.shortAddress }}
            </p>
            <JobPrice>{{ store.balance }}</JobPrice>
          </div>

          <Avatar :size="42" :address="store.address" />
        </div>
      </template>

      <template v-else>
        <Button :disabled="!isEthereum" @click="store.connect()">
          <div class="flex items-center gap-1.5">
            <Metamask class="text-lg" />
            connect
          </div>
        </Button>
      </template>
    </div>
  </nav>
</template>
