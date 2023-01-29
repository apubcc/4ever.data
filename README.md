# {Solution Name} - {One-liner}

## **Intro to {Solution Name}💡**

## **Main Features⚙️**

## The Stack🛠

- Package-Manager: `pnpm`
- Monorepo Tooling: `turborepo`
- Smart Contract Development: `hardhat`
  - Deploy & Address-Export: `hardhat-deploy`
  - Typescript-Types: `typechain`
- Frontend: `next`
  - Contract Interactions: `wagmi`, `rainbowkit`
  - Styling: `tailwindcss`
  - Styled Components: `twin.macro`, `emotion`
- Misc:
  - Linting & Formatting: `eslint`, `prettier`
  - Actions on Git Hooks: `husky`, `lint-staged`

## Getting Started🏃🏽‍♂️

```bash
# Install pnpm ** if you dont have it
npm i -g pnpm
# Install dependencies
pnpm install
# Copy & fill environments
cp packages/frontend/.env.local.example packages/frontend/.env.local
cp packages/contracts/.env.example packages/contracts/.env
```

## Development

```bash
# on terminal 1 
cd packages/contracts
yarn deploy
# on terminal 2 Generate contract-types, start local hardhat node, and start frontend with turborepo
pnpm dev
# Only start frontend
pnpm frontend:dev
```
