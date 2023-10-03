# Omnivore

Omnivore allows users to search for food trucks in San Francisco, based on food offered or application status -- or, if you're hungry but indecisive (and/or adventurous), it'll return a random truck. It pulls data from [the city of San Francisco's public api](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/data).

I got the idea to work with this API from [this assessment repo](https://github.com/peck/engineering-assessment).

I am going to continue building this out as a way to try out some new technologies and keep myself sharp while I'm looking for work. As of right now, I plan to get it basically functional, do some refactoring, then do the whole thing again in another stack.

### Requirements

- Ruby 3.0.0 or higher
- Rails 7.0 or higher
- Postgres 14 or higher (used 14 b/c happened to have that installed already)

### Setup

The easiest way to set this up, after cloning the repo, is just to run `bundle exec rake setup:complete`. It wraps up the traditional `bundle install` and `bundle exec rails db:setup` steps with another step, which pulls food truck data from the SF API and seeds the database.

Alternatively, the seeding can be done on its own, after everything else has been set up, with `bundle exec rake setup:seed_trucks`.

It's necessary to seed the trucks, however, since the app does not offer a direct connection to the SF API, so the importer is the only way to get that data.

It does take a minute to run all this. The truck import in particular could be made much more efficient, and will be, eventually. There's a ticket for that, anyway.

You can also import the trucks via a Rails console, instead of using the rake task, if you wish. `TruckImporter.perform` will sort you right out.

Originally, this used `Rails.credentials`, even though there's not a pressing need for it just yet. I haven't come up with a good way to share the encryption keys anyway, so there might be a stray reference to credentials, but that's just for the production env db, which was only ever another local PG instance, but with password protection.

### Usage

**Base URL**: `http://localhost:3000/api/v1/food_trucks`

This iteration of Omnivore simply offers a wrapper around the SF API, allowing users to query the trucks' menus for particular items, filter based on permit status, or see a random truck.

Eventually, this data will be consumed by a frontend that add a few additional features, like a history of users' visits, a ratings system and some kind of recommendation algorithm based on that stuff.

**Endpoint**: `/food_trucks`. Users have the options of including, as URL params, either `filters`, `q` (for keyword search) or both.

When both are present, the filters and keywords are applied using `AND` statements. Support for `OR` is upcoming. Or at least there's a ticket for it.

The one exception to the foregoing is `random`. When this is included in the filters, all other params are ignored. `FoodTruck.random` uses Postgres' `tablesample` in combination with `system`. There are shortcomings with the implementation, but this is more MVP/PoC than anything.

So, for example, to filter on only active trucks, a user should request that filter:

```
http://localhost:3000/api/v1/food_trucks?filters=active
```

or, via cURL:

```
curl -X GET "http://localhost:3000/api/v1/food_trucks?filters=active"
```

To submit a keyword search, say for "poke", you would use `q`:

```
http://localhost:3000/api/v1/food_trucks?q=poke
```

via cURL:

```
curl -X GET "http://localhost:3000/api/v1/food_trucks?q=poke"
```

To do both (skipping straight to cURL):

```
curl -X GET "http://localhost:3000/api/v1/food_trucks?q=poke&filters=inactive"
```

#### Available filters

**Filter values can be combined via comma-separated string**

- `active`: status of `APPROVED` and expirationdate in the future
- `expired`: status of `EXPIRED` OR expirationdate in the past
- `suspended`: status of `SUSPENDED`
- `inactive`: status of anything except `APPROVED` or `APPROVED` but `expirationdate` is past (includes `REQUESTED` status)
- `random`: uses PostgreSQL's `tablesample` in combination with `system`
  - when `filters` param includes `random`, all further filters and all query terms are ignored and a random truck is returned
  - currently uses `system(10)` as its strategy, and is recursive: it will always return a truck. using `10` seemed, in a highly unscientific survey, to be a reasonable compromise between processing time and likelihood of an empty result

- `q`: signifies a keyword search. comma-separated string. Only trucks with all these words in their `fooditems` are returned.


#### API Contract

This version relies on plain-old JSON representations of `FoodTruck` objects. Serialization will be formalized in later tickets.

For this version, `response.body` will contain this, if something is found:

```
{
  "data": [
    {
      "id": 70,
      "external_location_id": "1660527",
      "applicant": "Natan's Catering",
      "facilitytype": "Truck",
      "cnn": "15019101",
      "locationdescription": "MISSION BAY BLVD SOUTH: 03RD ST \\ MISSION BAY BLVD to 04TH ST \\ MISSION BAY BLVD (501 - 599)",
      "address": "Assessors Block 8732/Lot001",
      "permit": "22MFF-00073",
      "status": "APPROVED",
      "schedule": "http://bsm.sfdpw.org/PermitsTracker/reports/report.aspx?title=schedule&report=rptSchedule&params=permit=22MFF-00073&ExportPDF=1&Filename=22MFF-00073_schedule.pdf",
      "priorpermit": "1",
      "fooditems": "Burgers: melts: hot dogs: burritos:sandwiches: fries: onion rings: drinks",
      "approved": "2022-11-18T00:00:00.000Z",
      "received": "2022-11-18T00:00:00.000Z",
      "expirationdate": "2023-11-15T00:00:00.000Z",
      "longitude": -122.39079035556641,
      "latitude": 37.77070297609754,
      "created_at": "2023-08-13T18:43:01.430Z",
      "updated_at": "2023-08-13T18:43:01.430Z"
    }
  ]
}
```

### Other Resources

I tried to document as much of my decision-making process as possible, in addition to keeping notes on specific decisions. In addition to the documentation here in the README and whatever I add to this repo's wiki, here's what's out there:

  - I'm blogging about this project and its future iterations over here: https://hamwater.wordpress.com/tag/omnivore/
  - I'm using GH projects to organize my tickets: https://github.com/users/authorbeard/projects/1/views/1
    - The items/tickets there dealing with issues 1 through 18 pertain to this phase of the project.
  - I tend to write decent enough commit messages, which will be more verbose in this case.
  - I will collect those message and flesh them out in PR descriptions, when I do those.

