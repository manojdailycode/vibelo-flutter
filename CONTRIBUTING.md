# Contributing to Vibelo

Thank you for your interest in contributing to **Vibelo**! We welcome contributions from the community, whether it's bug fixes, feature requests, documentation improvements, or UI/UX enhancements.

## 🎯 How to Contribute

### 1. Report Bugs

Found a bug? Please open a [Bug Report](https://github.com/manojdailycode/vibelo/issues/new?template=bug_report.md) with:
- Clear description of the issue
- Steps to reproduce
- Expected vs. actual behavior
- Your device info (OS, Flutter version, etc.)

### 2. Request Features

Have an idea? Open a [Feature Request](https://github.com/manojdailycode/vibelo/issues/new?template=feature_request.md):
- Describe the feature
- Explain the use case
- Show any mockups or examples if applicable

### 3. Submit Code Changes

#### Prerequisites
- Flutter 3.32.0+
- Dart 3.2.0+
- Git

#### Steps to Submit

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/vibelo.git
   cd vibelo
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-amazing-feature
   ```

3. **Make your changes**
   - Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
   - Write clear, concise commit messages
   - Test your changes locally

4. **Install dependencies & format code**
   ```bash
   flutter pub get
   dart format lib/ test/
   ```

5. **Run tests** (if applicable)
   ```bash
   flutter test
   ```

6. **Commit & push**
   ```bash
   git commit -m "feat: add your feature description"
   git push origin feature/your-amazing-feature
   ```

7. **Open a Pull Request**
   - Link any related issues
   - Describe your changes clearly
   - Include screenshots/videos for UI changes
   - Reference [Pull Request Template](.github/pull_request_template.md)

## 📋 Coding Standards

### Dart/Flutter Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Use `const` constructors where possible

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

Example:
```bash
git commit -m "feat: add sleep timer to player screen"
git commit -m "fix: resolve playlist loading issue"
```

### File Structure
```
lib/
├── screens/      # UI pages
├── providers/    # State management
├── services/     # API & business logic
├── widgets/      # Reusable UI components
└── theme/        # Styling & themes
```

## 🧪 Testing

Before submitting, ensure your code:
- ✅ Builds without errors
- ✅ Runs without crashes
- ✅ Follows the style guide
- ✅ Is properly documented

```bash
flutter analyze
flutter test
flutter build apk --release
```

## 📝 Documentation

If you add new features, please update:
- **README.md** — Add feature to the feature list or setup instructions
- **CHANGELOG.md** — Document your changes under "Unreleased"
- **Code comments** — Explain complex logic

## 🔄 PR Review Process

1. A maintainer will review your PR
2. Changes might be requested
3. Once approved, your PR will be merged
4. Your contribution will be credited in the next release!

## ❓ Questions?

- Check existing [Issues](https://github.com/manojdailycode/vibelo/issues)
- Read the [README](README.md) and [CHANGELOG](CHANGELOG.md)
- Open a discussion or ask in a new issue

## 📄 Code of Conduct

We're committed to providing a welcoming, inclusive environment. Please:
- Be respectful and constructive
- Avoid harassment or discrimination
- Focus on the code, not the person
- Help others learn and grow

## 🙏 Thank You!

Your contributions make Vibelo better for everyone. We truly appreciate your effort!

---

**Happy coding! 🎵**
