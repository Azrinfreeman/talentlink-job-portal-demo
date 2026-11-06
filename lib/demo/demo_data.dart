// Entirely fictional sample content. Dates stay relevant whenever the demo runs.
String demoDate(int days) =>
    DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

const demoEmail = 'demo@talentlink.example';
const demoPassword = 'Demo123!';

const demoCompanies = [
  {
    'id': 'tech',
    'name': 'Northwind Digital Studio',
    'industry': 'Technology',
    'location': 'Metro City, Central Region',
    'phone': '03-0000 1001',
    'about':
        'A fictional product studio building mobile and web experiences. Flexible working hours and structured graduate mentoring.'
  },
  {
    'id': 'green',
    'name': 'Hijau Energy Solutions',
    'industry': 'Engineering',
    'location': 'Riverside, Central Region',
    'phone': '03-0000 1002',
    'about':
        'A fictional clean energy company helping communities adopt sustainable technology.'
  },
  {
    'id': 'creative',
    'name': 'Kreatif Learning Hub',
    'industry': 'Education',
    'location': 'Techpark, Central Region',
    'phone': '03-0000 1003',
    'about':
        'A fictional education team producing accessible courses and interactive learning materials.'
  },
];

const demoJobs = [
  {
    'id': 'flutter',
    'title': 'Junior Flutter Developer',
    'company': 'tech',
    'type': 'Full Time',
    'salary': 'RM 3,500 – 5,000',
    'description':
        'Build Flutter interfaces, connect APIs, and collaborate with designers. Familiarity with Dart and Git is useful. Graduates are welcome.',
    'positions': '2'
  },
  {
    'id': 'designer',
    'title': 'UI/UX Designer',
    'company': 'tech',
    'type': 'Full Time - Remote',
    'salary': 'RM 4,000 – 6,000',
    'description':
        'Design accessible interfaces, prototype user journeys, and run usability sessions. Bring a portfolio of your recent work.',
    'positions': '1'
  },
  {
    'id': 'engineer',
    'title': 'Project Engineer',
    'company': 'green',
    'type': 'Full Time',
    'salary': 'RM 4,000 – 5,500',
    'description':
        'Support renewable energy projects, coordinate site activities, and prepare technical reports. Engineering diploma or degree preferred.',
    'positions': '3'
  },
  {
    'id': 'marketing',
    'title': 'Digital Marketing Intern',
    'company': 'creative',
    'type': 'Intern',
    'salary': 'RM 1,000 – 1,500',
    'description':
        'Create campaign content, analyse engagement, and support learning events. A three to six month placement with mentoring.',
    'positions': '2'
  },
  {
    'id': 'support',
    'title': 'Customer Support Associate',
    'company': 'green',
    'type': 'Part Time',
    'salary': 'RM 1,800 – 2,500',
    'description':
        'Help customers with enquiries, keep service records, and work with the operations team. Training is provided.',
    'positions': '2'
  },
  {
    'id': 'content',
    'title': 'Learning Content Creator',
    'company': 'creative',
    'type': 'Contractual',
    'salary': 'RM 3,000 – 4,500',
    'description':
        'Develop short lessons, scripts, and assessments for digital learning. Strong writing and communication skills are useful.',
    'positions': '1'
  },
];

const demoCourses = [
  {
    'id': 'dart',
    'title': 'Flutter & Dart Essentials',
    'type': 'Training',
    'days': 7,
    'venue': 'Shah Alam Training Centre',
    'description':
        'A practical introduction to widgets, state, navigation, and testing. Bring a laptop; no prior Flutter experience required.'
  },
  {
    'id': 'interview',
    'title': 'Interview Confidence Workshop',
    'type': 'Webinar',
    'days': 10,
    'venue': 'Online demo classroom',
    'description':
        'Practise introducing yourself, structuring answers, and preparing questions for employers.'
  },
  {
    'id': 'green-careers',
    'title': 'Careers in Sustainable Energy',
    'type': 'Webinar',
    'days': 14,
    'venue': 'Online demo classroom',
    'description':
        'Explore emerging roles in clean energy and build a personal development plan.'
  },
  {
    'id': 'portfolio',
    'title': 'Build Your Professional Portfolio',
    'type': 'Training',
    'days': 21,
    'venue': 'Cyberjaya Learning Hub',
    'description':
        'Turn your projects into a portfolio and improve your CV through guided exercises.'
  },
];
