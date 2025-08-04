# Contributing to Self-Hosted VPN Server

Thank you for your interest in contributing to this project! We welcome contributions from the community to help improve and expand this self-hosted VPN solution.

## 📋 Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Guidelines](#development-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## 🤝 Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow:

### Our Standards
- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and help them learn
- **Be collaborative**: Work together to improve the project
- **Be constructive**: Provide helpful feedback and suggestions

### Unacceptable Behavior
- Harassment, discrimination, or offensive language
- Personal attacks or inflammatory comments
- Spam or excessive self-promotion
- Sharing others' private information without permission

## 🚀 Getting Started

### Prerequisites
- AWS account with EC2 access
- Basic Linux command line knowledge
- Understanding of networking concepts
- Git installed on your local machine

### Setting Up Development Environment
1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/self-hosted-vpn.git
   cd self-hosted-vpn
   ```
3. **Set up testing environment**:
   - Launch a test EC2 instance
   - Test the installation scripts
   - Verify all components work correctly

## 🛠️ How to Contribute

### Types of Contributions
We welcome various types of contributions:

#### 🐛 Bug Reports
- Use GitHub Issues to report bugs
- Include detailed reproduction steps
- Provide system information and logs
- Search existing issues before creating new ones

#### ✨ Feature Requests  
- Propose new features via GitHub Issues
- Explain the problem you're trying to solve
- Describe your proposed solution
- Consider implementation complexity

#### 📖 Documentation Improvements
- Fix typos and clarify instructions
- Add troubleshooting guides
- Create tutorials for specific use cases
- Improve code comments

#### 💻 Code Contributions
- Fix bugs and implement features
- Improve installation scripts
- Add monitoring and management tools
- Optimize performance

### Contribution Process

#### 1. Plan Your Contribution
- Check existing issues and pull requests
- Discuss large changes before implementation
- Create an issue for new features

#### 2. Make Your Changes
```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Test thoroughly
# ... run tests ...

# Commit with clear messages
git add .
git commit -m "Add feature: detailed description of changes"
```

#### 3. Submit a Pull Request
- Push your branch to your fork
- Create a pull request with:
  - Clear title and description
  - Reference related issues
  - Include testing information
  - Screenshots if applicable

## 📝 Development Guidelines

### Code Style
- **Shell Scripts**: Follow Google Shell Style Guide
- **Documentation**: Use clear, concise language
- **Comments**: Explain complex logic and decisions
- **Variables**: Use descriptive names

### File Organization
```
self-hosted-vpn/
├── README.md              # Main documentation
├── install.sh             # Automated installation
├── scripts/
│   ├── backup.sh          # Backup utilities
│   ├── monitor.sh         # Monitoring tools
│   └── client-manager.sh  # Client management
├── configs/
│   ├── wireguard-template.conf
│   ├── pihole-config-template.txt
│   └── unbound-config-template.conf
├── docs/
│   ├── TROUBLESHOOTING.md
│   ├── SECURITY.md
│   └── FAQ.md
└── examples/
    ├── docker-compose.yml
    └── terraform/
```

### Git Conventions
- **Commit Messages**: Use conventional commits format
  ```
  type(scope): description

  Examples:
  feat(install): add automatic backup configuration
  fix(wireguard): resolve client connection issues
  docs(readme): update installation instructions
  ```

- **Branch Names**: Use descriptive names
  ```
  feature/add-monitoring-dashboard
  bugfix/pihole-dns-resolution
  docs/update-troubleshooting-guide
  ```

## 🧪 Testing

### Manual Testing Checklist
Before submitting contributions, test the following:

#### Installation Testing
- [ ] Fresh EC2 instance installation
- [ ] All services start correctly
- [ ] PiHole admin interface accessible
- [ ] WireGuard tunnel connects successfully
- [ ] DNS resolution works through PiHole
- [ ] Ad blocking functions properly

#### Component Testing
- [ ] **PiHole**: Web interface, DNS filtering, query logging
- [ ] **WireGuard**: Client connections, traffic routing
- [ ] **Unbound**: Recursive DNS resolution, performance
- [ ] **System**: Resource usage, security settings

#### Script Testing
- [ ] Installation script runs without errors
- [ ] Backup script creates valid backups
- [ ] Monitoring script detects issues
- [ ] Client management tools work correctly

### Test Environments
- **Primary**: Ubuntu 22.04 LTS on AWS EC2 t2.micro
- **Secondary**: Different AWS regions and instance types
- **Clients**: Various devices (iOS, Android, Windows, macOS, Linux)

## 📚 Documentation

### Documentation Standards
- **Clear Structure**: Use headers and sections logically
- **Step-by-Step**: Provide detailed instructions
- **Screenshots**: Include visual aids when helpful
- **Examples**: Show practical usage examples
- **Troubleshooting**: Anticipate common issues

### Required Documentation Updates
When contributing code changes:
- Update README.md if functionality changes
- Add troubleshooting entries for new issues
- Update configuration templates if needed
- Include usage examples for new features

## 👥 Community

### Getting Help
- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For questions and general discussion
- **Wiki**: Community-maintained documentation

### Communication Guidelines
- **Be Clear**: Provide detailed information
- **Be Patient**: Allow time for responses
- **Be Helpful**: Share your knowledge with others
- **Search First**: Check existing resources before asking

### Recognition
Contributors will be recognized in:
- README.md acknowledgments section
- Release notes for significant contributions
- Special recognition for major improvements

## 🏷️ Issue Labels

We use labels to categorize issues and pull requests:

### Type Labels
- `bug` - Something isn't working correctly
- `enhancement` - New feature or improvement
- `documentation` - Documentation improvements
- `question` - Further information requested

### Priority Labels
- `critical` - Urgent fixes needed
- `high` - Important improvements
- `medium` - Standard priority
- `low` - Nice-to-have features

### Component Labels
- `pihole` - PiHole related issues
- `wireguard` - WireGuard VPN issues
- `unbound` - DNS resolver issues
- `aws` - AWS infrastructure issues
- `installation` - Setup and installation issues

## 📋 Pull Request Template

When creating a pull request, include:

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing functionality)
- [ ] Documentation update

## Testing
- [ ] Tested on fresh EC2 instance
- [ ] All existing functionality still works
- [ ] Added appropriate documentation
- [ ] Tested with multiple client devices

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes without discussion

## Related Issues
Fixes #(issue number)
```

## 🎯 Good First Issues

New contributors can start with these types of issues:
- Documentation improvements
- Adding troubleshooting guides
- Testing on different platforms
- Creating usage examples
- Improving error messages

Look for issues labeled `good-first-issue` to get started!

## 📞 Contact

- **Project Maintainer**: [Your GitHub Username]
- **Project Repository**: https://github.com/yourusername/self-hosted-vpn
- **Issue Tracker**: https://github.com/yourusername/self-hosted-vpn/issues

Thank you for contributing to making internet privacy more accessible! 🔐✨
