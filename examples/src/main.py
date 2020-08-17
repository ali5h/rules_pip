from google.cloud import language_v1 as lang

client = lang.LanguageServiceClient()

document = lang.types.Document(
    content="Google, headquartered in Mountain View, unveiled the "
    "new Android phone at the Consumer Electronic Show.  "
    "Sundar Pichai said in his keynote that users love "
    "their new Android phones.",
    language="en",
    type="PLAIN_TEXT",
)
