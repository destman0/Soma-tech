for text in one two three four five six seven eight nine ten inhale exhale hold
do aws polly synthesize-speech \
		--profile dyslexia-app \
		--language-code en-GB \
		--output-format mp3 \
		--voice-id Emma  \
		--text-type ssml \
		--text "<speak><prosody rate='75%'>$text</prosody></speak>" \
		audio/$text.mp3
done
