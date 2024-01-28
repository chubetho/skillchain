/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_MARKET_ADDRESS: string
  readonly VITE_CHAT_ADDRESS: string
  readonly VITE_COMMITTEE_ADDRESS: string
  readonly VITE_ESCROW_ADDRESS: string
  readonly VITE_JOB_ADDRESS: string
  readonly VITE_REVIEW_ADDRESS: string
  readonly VITE_USER_ADDRESS: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
