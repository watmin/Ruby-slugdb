# SlugDB

A completely Ruby, lightweight, zero dependency, NoSQL, file based databased.

I wanted a tiny database for an embedded project that could follow the advanced data modelling techniques for NoSQL. This is basically a very slimmed down SQLite but for NoSQL without any C bindings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slugdb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install slugdb

## Usage

First, go watch this: [![AWS re:Invent 2019: Amazon DynamoDB deep dive: Advanced design patterns (DAT403-R1)](https://img.youtube.com/vi/6yqfmXiZTlM/0.jpg)](https://www.youtube.com/watch?v=6yqfmXiZTlM)

Then watch it like a dozen more times, it'll click.

Basic usage

```ruby

require 'slugdb'
# => true

# Create a database

sdb = SlugDB.new('./data.slug')
# => #<SlugDB:0x000055bd9552c238
#  @pstore=
#   #<PStore:0x000055bd9552c210
#    @abort=false,
#    @filename="./data.slug",
#    @lock=#<Thread::Mutex:0x000055bd9552c148>,
#    @rdonly=false,
#    @table={:main=>{}, :indexes=>{}},
#    @thread_safe=false,
#    @ultra_safe=false>>

# Put some data in it

sdb.put_item(pk: 'awesome#partition#1#', sk: 'metadata#')
# => {:pk=>"awesome#partition#1#", :sk=>"metadata#"}

# Read it back

sdb.get_item(pk: 'awesome#partition#1#', sk: 'metadata#')
# => {:pk=>"awesome#partition#1#", :sk=>"metadata#"}

# Put in some more data

sdb.put_item(pk: 'awesome#partition#1#', sk: 'something#useful#')
# => {:pk=>"awesome#partition#1#", :sk=>"something#useful#"}

# Query our records

sdb.query(pk: 'awesome#partition#1#')
# => [{:pk=>"awesome#partition#1#", :sk=>"metadata#"},
#  {:pk=>"awesome#partition#1#", :sk=>"something#useful#"}]
```

Ok, but like... this is useful, how exactly?..

> Clearly you didn't watch the YouTube video, it's fine, no one does. Let me read it to you.

We're about to solve the following:
- Get meetings
  - by date and email
  - by date and employee id
  - by date and building/floor/room
- Load employee dashboard by email
  - get employee data
  - get meetings
  - get tickets
  - get reservations
  - get time cards
- Get employee info
  - by employed id
  - by email
- Get ticket history
  - by ticket id
  - by employee email
  - by assignee email
- Get employees
  - by city, building, floor, aisle, desk
  - by manager
- Get assigned tickets
  - by email
- Get tickets
  - by last touched greater than 24 hours ago
- Get projects
  - by status, start and target date
  - by name
- Get project history
  - by date range
  - by name
- Get rooms
  - by building id
  - by availability and time range

And like.. its really damn easy. Embrance the datas.

Let's go load all them datas into the bases.

```ruby
### Create a fresh table

sdb = SlugDB.new('./demo.slug')
# => #<SlugDB:0x00005612d2ad0120
#  @pstore=
#   #<PStore:0x00005612d2ad00f8
#    @abort=false,
#    @filename="./demo.slug",
#    @lock=#<Thread::Mutex:0x00005612d2ad0030>,
#    @rdonly=false,
#    @table={:main=>{}, :indexes=>{}},
#    @thread_safe=false,
#    @ultra_safe=false>>

### Create some indexes

sdb.add_index(name: :ski, pk: :sk, sk: :pk)
# => {:name=>{:pk=>:sk, :sk=>:pk}}
sdb.add_index(name: :gsi1, pk: :gsi1_pk, sk: :gsi1_sk)
# => {:name=>{:pk=>:gsi1_pk, :sk=>:gsi1_sk}}
sdb.add_index(name: :gsi2, pk: :gsi2_pk, sk: :gsi2_sk)
# => {:name=>{:pk=>:gsi2_pk, :sk=>:gsi2_sk}}
sdb.add_index(name: :gsi3, pk: :gsi3_pk, sk: :gsi3_sk)
# => {:name=>{:pk=>:gsi3_pk, :sk=>:gsi3_sk}}

### Create some records

sdb.put_item(
  pk: 'yxz58',
  sk: '2021-03-04T10:00:00Z|10.106',
  gsi1_pk: 'john@shields.wtf',
  gsi1_sk: '2021-03-04T10:00:00Z|10.106',
  duration: 30,
  attendees: ['notjohn@shields.wtf', 'john@shields.wtf'],
  subject: 'Discuss Project How does NoSQL?'
)
# => {:gsi1_pk=>"john@shields.wtf",
#  :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#  :duration=>30,
#  :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#  :subject=>"Discuss Project How does NoSQL?",
#  :pk=>"yxz58",
#  :sk=>"2021-03-04T10:00:00Z|10.106"}
sdb.put_item(
  pk: 'yxz58',
  sk: '2021-03-04T10:15:00Z|10.106',
  attendees: ['notjohn@shields.wtf', 'john@shields.wtf'],
  subject: 'Discuss Project How does NoSQL?',
  organizer: 'john@shields.wtf'
)
# => {:attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#  :subject=>"Discuss Project How does NoSQL?",
#  :organizer=>"john@shields.wtf",
#  :pk=>"yxz58",
#  :sk=>"2021-03-04T10:15:00Z|10.106"}
sdb.put_item(
  pk: 'yxz58',
  sk: 'rooms',
  room_spec: {
    some: 'data',
    more: 'and more'
  }
)
# => {:room_spec=>{:some=>"data", :more=>"and more"}, :pk=>"yxz58", :sk=>"rooms"}

sdb.put_item(
  pk: 'employee#1',
  sk: '2021-03-04T10:00:00Z|10.106',
  gsi1_pk: 'notjohn@shields.wtf',
  gsi1_sk: '2021-03-04T10:00:00Z|10.106',
  duration: 30,
  attendees: ['notjohn@shields.wtf', 'john@shields.wtf'],
  subject: 'Discuss Project How does NoSQL?'
)
# => {:gsi1_pk=>"notjohn@shields.wtf",
#  :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#  :duration=>30,
#  :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#  :subject=>"Discuss Project How does NoSQL?",
#  :pk=>"employee#1",
#  :sk=>"2021-03-04T10:00:00Z|10.106"}
sdb.put_item(
  pk: 'employee#1',
  sk: 'ext#965',
  gsi1_pk: 'notjohn@shields.wtf',
  gsi1_sk: 'ext#965',
  gsi3_pk: 'yxz',
  gsi3_sk: '10.11.123.G9',
  name: 'Not John',
  title: 'Imposter',
  gsi2_pk: 'notjohn@shields.wtf',
  gsi2_sk: nil
)
# => {:gsi1_pk=>"notjohn@shields.wtf",
#  :gsi1_sk=>"ext#965",
#  :gsi3_pk=>"yxz",
#  :gsi3_sk=>"10.11.123.G9",
#  :name=>"Not John",
#  :title=>"Imposter",
#  :gsi2_pk=>"notjohn@shields.wtf",
#  :gsi2_sk=>nil,
#  :pk=>"employee#1",
#  :sk=>"ext#965"}

sdb.put_item(
  pk: 'employee#2',
  sk: 'ext#293',
  gsi1_pk: 'john@shields.wtf',
  gsi1_sk: 'ext#293',
  gsi3_pk: 'yxz',
  gsi3_sk: '11.10.123.G9',
  name: 'Actual John',
  title: 'Real',
  gsi2_pk: 'john@shields.wtf',
  gsi2_sk: nil
)
# => {:gsi1_pk=>"john@shields.wtf",
#  :gsi1_sk=>"ext#293",
#  :gsi3_pk=>"yxz",
#  :gsi3_sk=>"11.10.123.G9",
#  :name=>"Actual John",
#  :title=>"Real",
#  :gsi2_pk=>"john@shields.wtf",
#  :gsi2_sk=>nil,
#  :pk=>"employee#2",
#  :sk=>"ext#293"}

sdb.put_item(
  pk: 'Project How does NoSQL?',
  sk: '2021-03-04#john@shields.wtf',
  gsi1_pk: 'john@shields.wtf',
  gsi1_sk: '2021-03-04',
  hours: 12,
  role: 'Lord of Data'
)
# => {:gsi1_pk=>"john@shields.wtf",
#  :gsi1_sk=>"2021-03-04",
#  :hours=>12,
#  :role=>"Lord of Data",
#  :pk=>"Project How does NoSQL?",
#  :sk=>"2021-03-04#john@shields.wtf"}
sdb.put_item(
  pk: 'Project How does NoSQL?',
  sk: '2021-03-04#notjohn@shields.wtf',
  gsi1_pk: 'notjohn@shields.wtf',
  gsi1_sk: '2021-03-04',
  hours: 24,
  role: 'Not as cool'
)
# => {:gsi1_pk=>"notjohn@shields.wtf",
#  :gsi1_sk=>"2021-03-04",
#  :hours=>24,
#  :role=>"Not as cool",
#  :pk=>"Project How does NoSQL?",
#  :sk=>"2021-03-04#notjohn@shields.wtf"}
sdb.put_item(
  pk: 'Project How does NoSQL?',
  sk: 'Project How does NoSQL?',
  gsi1_pk: 'Active',
  gsi1_sk: '2021-02-25',
  description: 'A project, darkly',
  target_delivery: '2021-04-15'
)
# => {:gsi1_pk=>"Active",
#  :gsi1_sk=>"2021-02-25",
#  :description=>"A project, darkly",
#  :target_delivery=>"2021-04-15",
#  :pk=>"Project How does NoSQL?",
#  :sk=>"Project How does NoSQL?"}

sdb.put_item(
  pk: 'ticket#1',
  sk: '2021-03-04T10:30:29Z',
  gsi1_pk: 'john@shields.wtf',
  gsi1_sk: '2021-03-04T10:30:29Z',
  subject: 'halp',
  gsi3_pk: '7',
  gsi3_sk: '2021-03-04T10:30:29Z',
  gsi2_pk: 'notjohn@shields.wtf',
  gsi2_sk: 'need halps, datas iz hard'
)
# => {:gsi1_pk=>"john@shields.wtf",
#  :gsi1_sk=>"2021-03-04T10:30:29Z",
#  :subject=>"halp",
#  :gsi3_pk=>'7',
#  :gsi3_sk=>"2021-03-04T10:30:29Z",
#  :gsi2_pk=>"notjohn@shields.wtf",
#  :gsi2_sk=>"need halps, datas iz hard",
#  :pk=>"ticket#1",
#  :sk=>"2021-03-04T10:30:29Z"}
sdb.put_item(
  pk: 'ticket#1',
  sk: '2021-03-04T10:35:46Z',
  gsi1_pk: 'john@shields.wtf',
  gsi1_sk: '2021-03-04T10:35:46Z',
  gsi2_pk: 'notjohn@shields.wtf',
  message: 'ack, halps requested'
)
# => {:gsi1_pk=>"john@shields.wtf",
#  :gsi1_sk=>"2021-03-04T10:35:46Z",
#  :gsi2_pk=>"notjohn@shields.wtf",
#  :message=>"ack, halps requested",
#  :pk=>"ticket#1",
#  :sk=>"2021-03-04T10:35:46Z"}

### Ok, let's get meetings by date and employee id and toss in a filter for greater than zero duration

sdb.query(
  pk: 'employee#1',
  select: ->(sk) { sk >= '2021-03-03T10:00:00Z' && sk <= '2021-03-05T10:00:00Z' },
  filter: ->(item) { !item[:duration].nil? && item[:duration] > 0 }
)
# => [{:gsi1_pk=>"notjohn@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#   :duration=>30,
#   :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :pk=>"employee#1",
#   :sk=>"2021-03-04T10:00:00Z|10.106"}]

### Neat, now let's get meetings by date a building/floor/room

sdb.query(
  pk: 'yxz58',
  select: ->(sk) { sk >= '2021-03-03T10:00:00Z' && sk <= '2021-03-05T10:00:00Z' },
  filter: ->(item) { item[:sk] =~ /\|10\./ }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#   :duration=>30,
#   :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:00:00Z|10.106"},
#  {:attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :organizer=>"john@shields.wtf",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:15:00Z|10.106"}]

### I'm not a wizard, maybe a sorceror. How about getting employee info by employee id

sdb.query(
  pk: 'employee#2',
  select: ->(sk) { sk.start_with?('ext#') }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"ext#293",
#   :gsi3_pk=>"yxz",
#   :gsi3_sk=>"11.10.123.G9",
#   :name=>"Actual John",
#   :title=>"Real",
#   :gsi2_pk=>"john@shields.wtf",
#   :gsi2_sk=>nil,
#   :pk=>"employee#2",
#   :sk=>"ext#293"}]

### That was a bit too easy, maybe not a sorceror. Some spell have a long cast time. Where's my ticket history?

sdb.query(pk: 'ticket#1')
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:30:29Z",
#   :subject=>"halp",
#   :gsi3_pk=>'7',
#   :gsi3_sk=>"2021-03-04T10:30:29Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>"need halps, datas iz hard",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:30:29Z"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:35:46Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :message=>"ack, halps requested",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:35:46Z"}]

### Yeah.. a little **too** easy, right? Can I get project info?

sdb.query(
  pk: 'Project How does NoSQL?',
  select: ->(sk) { sk == 'Project How does NoSQL?' }
)
# => [{:gsi1_pk=>"Active",
#   :gsi1_sk=>"2021-02-25",
#   :description=>"A project, darkly",
#   :target_delivery=>"2021-04-15",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"Project How does NoSQL?"}]

### I'm wondering if I even NoSQL? Can I get project history?

sdb.query(
  pk: 'Project How does NoSQL?',
  select: ->(sk) { sk >= '2021-03-03' && sk <= '2021-03-05' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04",
#   :hours=>12,
#   :role=>"Lord of Data",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"2021-03-04#john@shields.wtf"},
#  {:gsi1_pk=>"notjohn@shields.wtf",
#   :gsi1_sk=>"2021-03-04",
#   :hours=>24,
#   :role=>"Not as cool",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"2021-03-04#notjohn@shields.wtf"}]

### I think I can NoSQL, gimme dem projects by role

sdb.query(
  pk: 'Project How does NoSQL?',
  filter: ->(item) { item[:role] == 'Lord of Data' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04",
#   :hours=>12,
#   :role=>"Lord of Data",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"2021-03-04#john@shields.wtf"}]

### I still have way more to, I need a seat, got a room that'll work?

sdb.query(
  pk: 'yxz58',
  select: ->(sk) { sk == 'rooms' }
)
# => [{:room_spec=>
#    {:some=>"data",
#     :more=>"and more"},
#   :pk=>"yxz58",
#   :sk=>"rooms"}]

### Nice, is that room available?

sdb.query(
  pk: 'yxz58',
  select: ->(sk) { sk >= '2021-03-03T09:00:00Z' && sk <= '2021-03-05T18:00:00Z' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#   :duration=>30,
#   :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:00:00Z|10.106"},
#  {:attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :organizer=>"john@shields.wtf",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:15:00Z|10.106"}]


### Book it! But, am I busy? My sorcery is bubbling up...

sdb.query(
  index: :gsi1,
  pk: 'john@shields.wtf',
  select: ->(sk) { sk >= '2021-03-03T09:00:00Z' && sk <= '2021-03-05T18:00:00Z' },
  filter: ->(item) { !item[:duration].nil? && item[:duration] > 0 }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#   :duration=>30,
#   :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:00:00Z|10.106"}]

### MMMM.. Dems some good datas. Gimme more datas!! I need to render a dashbaord

sdb.query(
  index: :gsi1,
  pk: 'john@shields.wtf',
  select: ->(sk) { sk >= '2021-02-03T09:00:00Z' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:00:00Z|10.106",
#   :duration=>30,
#   :attendees=>["notjohn@shields.wtf", "john@shields.wtf"],
#   :subject=>"Discuss Project How does NoSQL?",
#   :pk=>"yxz58",
#   :sk=>"2021-03-04T10:00:00Z|10.106"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"ext#293",
#   :gsi3_pk=>"yxz",
#   :gsi3_sk=>"11.10.123.G9",
#   :name=>"Actual John",
#   :title=>"Real",
#   :gsi2_pk=>"john@shields.wtf",
#   :gsi2_sk=>nil,
#   :pk=>"employee#2",
#   :sk=>"ext#293"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04",
#   :hours=>12,
#   :role=>"Lord of Data",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"2021-03-04#john@shields.wtf"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:30:29Z",
#   :subject=>"halp",
#   :gsi3_pk=>'7',
#   :gsi3_sk=>"2021-03-04T10:30:29Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>"need halps, datas iz hard",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:30:29Z"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:35:46Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :message=>"ack, halps requested",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:35:46Z"}]

### Truly magical! Hit with some more info

sdb.query(
  index: :gsi1,
  pk: 'john@shields.wtf',
  select: ->(sk) { sk.start_with?('ext#') }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"ext#293",
#   :gsi3_pk=>"yxz",
#   :gsi3_sk=>"11.10.123.G9",
#   :name=>"Actual John",
#   :title=>"Real",
#   :gsi2_pk=>"john@shields.wtf",
#   :gsi2_sk=>nil,
#   :pk=>"employee#2",
#   :sk=>"ext#293"}]

### Delicious, how about some ticket history?

sdb.query(
  index: :gsi1,
  pk: 'john@shields.wtf',
  filter: ->(item) { item[:pk] == 'ticket#1' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:30:29Z",
#   :subject=>"halp",
#   :gsi3_pk=>'7',
#   :gsi3_sk=>"2021-03-04T10:30:29Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>"need halps, datas iz hard",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:30:29Z"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:35:46Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :message=>"ack, halps requested",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:35:46Z"}]

### Is it setting in yet? How much you totally don't know about NoSQL? Can you riddle me this? What active projects do I have?

sdb.query(
  index: :gsi1,
  pk: 'Active',
  select: ->(sk) { sk >= '2021-02-25' },
  filter: ->(item) { item[:target_delivery] < '2021-05-01' }
)
# => [{:gsi1_pk=>"Active",
#   :gsi1_sk=>"2021-02-25",
#   :description=>"A project, darkly",
#   :target_delivery=>"2021-04-15",
#   :pk=>"Project How does NoSQL?",
#   :sk=>"Project How does NoSQL?"}]

### We're still not done yet, we've only used a single index so far. Give me the ticket history by assignee

sdb.query(
  index: :gsi2,
  pk: 'notjohn@shields.wtf',
  filter: ->(item) { item[:pk] == 'ticket#1' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:30:29Z",
#   :subject=>"halp",
#   :gsi3_pk=>'7',
#   :gsi3_sk=>"2021-03-04T10:30:29Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>"need halps, datas iz hard",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:30:29Z"}]

### Neato, I'm still not out of tricks. Can you give me all employees by location?

sdb.query(
  index: :gsi3,
  pk: 'yxz',
  select: ->(sk) { sk.start_with?('10.11') }
)
# => [{:gsi1_pk=>"notjohn@shields.wtf",
#   :gsi1_sk=>"ext#965",
#   :gsi3_pk=>"yxz",
#   :gsi3_sk=>"10.11.123.G9",
#   :name=>"Not John",
#   :title=>"Imposter",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>nil,
#   :pk=>"employee#1",
#   :sk=>"ext#965"},
#  {:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"ext#293",
#   :gsi3_pk=>"yxz",
#   :gsi3_sk=>"10.11.124.G9",
#   :name=>"Actual John",
#   :title=>"Real",
#   :gsi2_pk=>"john@shields.wtf",
#   :gsi2_sk=>nil,
#   :pk=>"employee#2",
#   :sk=>"ext#293"}]

### Final trick.. for now.. show me all the tickets that haven't bene dealt with recently

sdb.query(
  index: :gsi3,
  pk: '7',
  select: ->(sk) { sk < '2021-03-06T10:30:29Z' }
)
# => [{:gsi1_pk=>"john@shields.wtf",
#   :gsi1_sk=>"2021-03-04T10:30:29Z",
#   :subject=>"halp",
#   :gsi3_pk=>'7',
#   :gsi3_sk=>"2021-03-04T10:30:29Z",
#   :gsi2_pk=>"notjohn@shields.wtf",
#   :gsi2_sk=>"need halps, datas iz hard",
#   :pk=>"ticket#1",
#   :sk=>"2021-03-04T10:30:29Z"}]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/watmin/Ruby-slugdb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/watmin/Ruby-slugdb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SlugDB project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/watmin/Ruby-slugdb/blob/master/CODE_OF_CONDUCT.md).
