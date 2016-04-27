CCClient = require 'constantcontact'
moment = require 'moment'

module.exports = (apiKey, accessTocken) ->

  getCCClient = ->
    client = new CCClient()
    client.useKey apiKey
    client.useToken accessTocken
    client

  _getEventData = (data) ->
    eventName = data.hotelLocation + ' ' + data.name

    event =
      address:
        city: data.city
        postal_code: data.zip
        state: data.state
        line1: data.address
      contact:
        email_address: data.supportEmail
        name: data.instructorName
      location: data.hotelLocation
      description: data.description
      currency_type: "USD"
      start_date: new Date parseInt data.start
      end_date: new Date parseInt data.end
      time_zone_id: data.timezone
      title: eventName
      name: eventName
      type: "BUSINESS_FINANCE_SALES"

    if data.active is 'true'
      event.status = "ACTIVE"
    else
      event.status = "DRAFT"

    event


  createEvent = (data, cb) ->
    event = _getEventData data

    getCCClient().eventspot.post event, (err, postRespose) ->
      cb err, postRespose if err

      return cb err, postRespose if event.status is 'DRAFT'

      patch = [{
        "op": "REPLACE",
        "path": "#/status",
        "value":  'ACTIVE'
      }]

      getCCClient().eventspot.patch postRespose.id, patch, (err, patchRespose) ->
        cb err, postRespose

  updateEvent = (data, cb) ->
    event = _getEventData data

    getCCClient().eventspot.put data.ccEventId, event, (err, respose) ->

      return  cb err, respose if err

      patch = [{
        "op": "REPLACE",
        "path": "#/status",
        "value": if event.status is 'ACTIVE' then 'ACTIVE' else 'CANCELLED'
      }]

      getCCClient().eventspot.patch data.ccEventId, patch, (err, respose) ->
        cb err, respose

  createContact = (data, cb) ->
    countryCodes =
      USA: 'US'
      Canada: 'CA'
      Mexico: 'MX'

    contact =
      addresses: [
        address_type: 'BUSINESS'
        city: data.city
        state: data.state
        postal_code: data.zip
      ]
      cell_phone: data.phone
      created_date: new Date()
      company_name: data.company
      custom_fields: [
        name: 'CustomField1'
        value: data.seminarAddress ? ''
      ,
        name: 'CustomField2'
        value: moment(data.start).format('MMM DD, YYYY  hh:mmA ') + moment(data.start).format('hh:mmA')
      ,
        name: 'CustomField4'
        value: data.seminarInstructorName + ''
      ,
        name: 'CustomField3'
        value: data.promocodeName ? ''
      ,
        name: 'CustomField5'
        value: data.seminarFee + ''
      ,
        name: 'CustomField6'
        value: data.total + ''
      ]
      email_addresses: [
        email_address: data.email
      ]
      lists: [
        id: data.ccListId
      ]
      prefix_name: data.salutation
      first_name: data.firstname
      last_name: data.lastname
      job_title: data.title
      source: 'from spasigma site'
      status: 'ACTIVE'

    if countryCode = countryCodes[data.country]
      contact.addresses[0].country_code = countryCode

    getCCClient().contacts.post contact, true, (err, respose) ->
      cb err, respose

  getContactsList = (cb) ->
    getCCClient().lists.get (err, respose) ->
      cb err, respose

  createContactsList = (name, cb) ->
    list =
      created_date: new Date()
      name: name
      status: "ACTIVE"

    getCCClient().lists.post list, (err, respose) ->
      cb err, respose


  {createEvent, createContact, getContactsList, createContactsList, updateEvent}