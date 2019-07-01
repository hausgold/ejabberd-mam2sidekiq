# Sidekiq XML Event Messages

## Direct Chat Message

```xml
<event xmlns="xmpp:mam:hausgold:sidekiq">
  <meta
    type='chat'
    from='bob@jabber.local'
    to='alice@jabber.local'
    id='1560857013427582'>
    <from jid="bob@jabber.local">
      <vCard>..</vCard>
    </from>
    <to jid="alice@jabber.local">
      <vCard>..</vCard>
    </to>
  </meta>
  <message
    xml:lang='en'
    to='alice@jabber.local'
    from='bob@jabber.local/98198947957023277897618'
    id='40dc0a07-acaa-4585-988b-1c7e151b97d5'
    xmlns='jabber:client'>
    <body>
      Try to copy the THX protocol, maybe it will
      calculate the auxiliary matrix!
    </body>
  </message>
</event>
```

## Group Chat (MUC) Message

```xml
<event xmlns="xmpp:mam:hausgold:sidekiq">
  <meta
    type='groupchat'
    from='bob@jabber.local'
    to='room-name@conference.jabber.local'
    id='1560857013427582'>
    <from jid="bob@jabber.local">
      <vCard>..</vCard>
    </from>
    <!-- All MUC room participants as <to> elements -->
    <to jid="alice@jabber.local">
      <vCard>..</vCard>
    </to>
    <to jid="romeo@jabber.local">
      <vCard>..</vCard>
    </to>
    <to jid="juliet@jabber.local">
      <vCard>..</vCard>
    </to>
  </meta>
  <message
    xml:lang='en'
    to='room-name@conference.jabber.local'
    from='bob@jabber.local/98198947957023277897618'
    id='40dc0a07-acaa-4585-988b-1c7e151b97d5'
    xmlns='jabber:client'>
    <body>
      Try to copy the THX protocol, maybe it will
      calculate the auxiliary matrix!
    </body>
  </message>
</event>
```

## vCard for a single contact

```xml
<vCard xmlns='vcard-temp'>
  <FN>Max Mustermann</FN>
  <N>
    <FAMILY>Mustermann</FAMILY>
    <GIVEN>Max</GIVEN>
  </N>
  <URL>gid://maklerportal-api/User/b8346717-6e04-4e52-8799-cb5dce7858df</URL>
  <ROLE>broker</ROLE>
</vCard>
```
