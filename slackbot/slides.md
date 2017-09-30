---
title: Building a slackbot to annoy your colleagues
author: John Children
date: September 2017
---

# What is Slack?

IRC for hipsters with gifs.

# Motivation

I spend a lot of time on Slack so anything that makes it more enjoyable is good.

# Custom Responses

![Example reponses](images/custom_responses.png)

# Problems

- Very inflexible, just match one of several phrases.
- More annoying than intented as they can happen in any channel.

# Custom Bots

- Join channels only on invitation.
- Can have silly names.
- Are able to process messages however you want.

# DavidHunt

``` python
import time
import slackclient


client = slackClient(token=API_TOKEN)
client.rtm_connect()


while True:
    davidHunt = client.rtm_read()
    for lead in davidHunt:
        # filter out non-message payloads
        if lead.get("type") != "message":
            continue

        channel = lead["channel"]

        msg_lead = lead.get("text", "")
        if "david" in msg_text:
            reply = "Whoops! Didn't you mean @duncan?"
            client.rtm_send_message(channel, reply)
    time.sleep(1)
```

# Retrospective

- Pretty basic but it means we can control what channel the reponses happen in.
- Can be turned on and off by just running the bot on a personal machine.
- Potentially could be deployed to AWS easily if needed. 

# Quotes

``` python
import random

QUOTES = ["something silly", "something equally silly"]

reply = random.choice(QUOTES)
```

# Retrospective

- Now we can do everything custom responses can do.
- Still quite limited in what we can do.
- Let's do something slackbot can't.

# SlackBot Library

- Gives us better modular structure for these features.
- Lets us create a single bot that is more easily managed.
- Single features can be expressed as functions with decorators.

# Real or Not Real
``` python
@respond_to("is (.*) a real number", re.IGNORECASE)
def real_or_not_real(message, number):
    try:
        message.reply('yes, {} is a real number'.format(float(number)))
    except:
        message.reply('no, {} is not a real number'.format(number))
```

# Markov Chains

- (explaination of some kind)

# Markov chains in python

``` python
import markovify

model = markovify.Text(text, 3)

message.send(model.make_sentence())
```

# Corpus

Let's make it cultured. Collect text files for:

- The Bible
- Complete works of Shakespeare
- Every Sherlock Holmes

# Mistakes were made

"If this be error and upon social questions
    which I am Misanthropos, and hate mankind."
                ~ MarkovBot


# Better Corpus ?

- Collect script for every episode of Seinfeld via requests library.
- Find all of Jerry's lines and strip off his name.
- Use them to build the corpus.
- Throw in the entire Bee Movie script for good measure.

# Results

- "He's nice, bit of a surprise to me."
- "You're gonna take this kid to the top."
- "I'm just a little bee!"

#

![Too far](images/gone_too_far.jpg)
