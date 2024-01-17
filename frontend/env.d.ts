/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_ACCOUNT_ADDRESS: string
  readonly VITE_ACCOUNT_KEY: string

  readonly VITE_MARKET_ADDRESS: string
  readonly VITE_JOB_ADDRESS: string
  readonly VITE_USER_ADDRESS: string
  readonly VITE_ESCROW_ADDRESS: string
  readonly VITE_CHAT_ADDRESS: string
  readonly VITE_REVIEW_ADDRESS: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
