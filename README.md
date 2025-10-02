# AI Career Advisor

An AI-powered career guidance tool that suggests learning paths, job matches, and skill development plans using blockchain technology on the Stacks network.

## Overview

The AI Career Advisor is a decentralized application that leverages smart contracts to provide transparent and immutable career guidance services. The system analyzes user profiles, resumes, and skill sets to provide personalized career recommendations while ensuring data privacy and security through blockchain technology.

## Key Features

### Resume Analysis
- **Automated Resume Parsing**: Extract skills, experience, and qualifications from uploaded resumes
- **Skill Gap Identification**: Compare user skills against industry requirements
- **Career Path Recommendations**: Suggest optimal career trajectories based on current profile
- **Learning Path Generation**: Recommend courses and certifications to bridge skill gaps

### Job Matching
- **Intelligent Job Recommendations**: Match user profiles with suitable job opportunities
- **Compatibility Scoring**: Calculate fit percentage between user skills and job requirements
- **Market Trend Analysis**: Provide insights on trending skills and job markets
- **Salary Benchmarking**: Compare compensation packages across similar roles

## Smart Contract Architecture

### Resume Analyzer Contract
The resume analyzer contract handles:
- User profile storage and management
- Skill assessment and gap analysis
- Career path recommendation engine
- Learning resource suggestions

### Job Matcher Contract
The job matcher contract manages:
- Job opportunity listings and matching
- User preference tracking
- Compatibility score calculations
- Application tracking and recommendations

## Technology Stack

- **Blockchain**: Stacks Network
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing**: Clarinet integrated testing suite

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for interaction
- Node.js for local development

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/somoore4u/ai-career-advisor.git
   cd ai-career-advisor
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run tests:
   ```bash
   clarinet test
   ```

4. Check contracts:
   ```bash
   clarinet check
   ```

## Contract Deployment

### Local Development
```bash
clarinet console
```

### Testnet Deployment
```bash
clarinet deploy --testnet
```

## Usage

### For Job Seekers
1. Create a profile by uploading your resume
2. Receive automated skill assessment and gap analysis
3. Get personalized job recommendations
4. Access learning resources to improve your profile
5. Track application progress and interview opportunities

### For Employers
1. List job opportunities with detailed requirements
2. Access candidate matching based on compatibility scores
3. Review candidate profiles and skill assessments
4. Track hiring pipeline and candidate interactions

## Smart Contract Functions

### Resume Analyzer
- `create-profile`: Initialize user career profile
- `analyze-skills`: Assess current skill set and identify gaps
- `get-recommendations`: Retrieve personalized career suggestions
- `track-progress`: Monitor skill development over time

### Job Matcher
- `submit-job-listing`: Add new job opportunities
- `find-matches`: Discover compatible job opportunities
- `calculate-fit`: Determine compatibility percentage
- `apply-for-job`: Submit job applications through the platform

## Data Privacy & Security

- **On-chain Storage**: Critical data stored immutably on blockchain
- **Privacy Protection**: Personal information encrypted and access-controlled
- **Transparent Algorithms**: Recommendation logic visible and auditable
- **User Control**: Full ownership and control over personal career data

## Roadmap

- [ ] Core smart contract development
- [ ] Basic resume analysis functionality
- [ ] Job matching algorithm implementation
- [ ] Web interface development
- [ ] Mobile application
- [ ] AI/ML integration for advanced recommendations
- [ ] Enterprise integration features

## Contributing

We welcome contributions to the AI Career Advisor project. Please read our contributing guidelines and code of conduct before submitting pull requests.

### Development Process
1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit pull request for review

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Join our community discussions

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Hiro for Clarinet development tools
- Open source community for contributions and feedback

---

*Building the future of decentralized career guidance, one smart contract at a time.*