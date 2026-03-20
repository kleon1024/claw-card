# Contributing to Claw Card

Thanks for your interest in contributing!

## Getting Started

1. Fork the repo
2. Clone and open in Godot 4.6+: `godot --editor --path .`
3. Make your changes on a feature branch
4. Submit a pull request

## Code Style

- GDScript: `snake_case` for variables/functions, `PascalCase` for classes
- Type hints where possible: `var hp: int = 80`
- Max 300 lines per file — split if larger
- Commit format: `<type>(<scope>): <subject>` (e.g., `feat(cards): add 10 water cards`)

## Game Data

Cards, enemies, and balance are defined in `data/*.json`. To add a card:

1. Add entry to `data/cards.json`
2. Add card art to `assets/sprites/cards/card_{id}.png` (256x256 recommended)
3. Test with `godot --path .`

## Art

Sprites are AI-generated (DreamShaper XL). If contributing art:
- Match the cozy deep-sea pixel art style
- 256x256 for cards, 512x512 for characters
- PNG with transparency

## License

By contributing, you agree that your contributions will be licensed under MIT.
