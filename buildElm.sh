#!/bin/bash
elm make src/elm/Home.elm --optimize --output=public/home.js
elm make src/elm/TimeAttack.elm --optimize --output=public/timeAttack.js
elm make src/elm/Translate.elm --optimize --output=public/translate.js
