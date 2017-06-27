# {{ ansible_managed }}
# -*- coding: utf-8 -*-

# import os
# from pathlib import Path

BUCKET_MIN = 20

SYNONYMS_PATH = None

# Pipeline stream to be used.
PROCESSORS_PYPATHS = [  # Rename in TOKEN_PROCESSORS / STRING_PROCESSORS?
    "addok.helpers.text.tokenize",
    "addok.helpers.text.normalize",
    "addok_france.glue_ordinal",
    "addok_france.fold_ordinal",
    "addok_france.flag_housenumber",
    "addok.helpers.text.synonymize",
    "addok_fr.phonemicize",
]
QUERY_PROCESSORS_PYPATHS = [
    'addok_france_clean.clean_query',
    'addok.helpers.text.check_query_length',
    'addok_france.extract_address',
    'addok_france.clean_query',
    'addok_france.remove_leading_zeros',
]
SEARCH_RESULT_PROCESSORS_PYPATHS = [
    "addok.helpers.results.match_housenumber",
    "addok_france.make_labels",
    "addok_usage_name_BAN_FR.make_labels",
    "addok.helpers.results.score_by_importance",
    "addok.helpers.results.score_by_autocomplete_distance",
    "addok.helpers.results.score_by_ngram_distance",
    "addok.helpers.results.score_by_geo_distance",
]

# Fields to be indexed
# If you want a housenumbers field but need to name it differently, just add
# type="housenumbers" to your field.
FIELDS = [
    {'key': 'name', 'boost': 4, 'null': False},
    {'key': 'street'},
    {'key': 'postcode',
     'boost': lambda doc: 1.2 if doc.get('type') == 'municipality' else 1},
    {'key': 'city'},
    {'key': 'housenumbers'},
    {'key': 'context'},
]

# Sometimes you only want to add some fields keeping the default ones.
EXTRA_FIELDS = []

# Data attribution
# Can also be an object {source: attribution}
ATTRIBUTION = "BANO"

# Data licence
# Can also be an object {source: licence}
LICENCE = "ODbL"

# Available filters (remember that every filter means bigger index)
FILTERS = ["type", "postcode", "citycode"]

LOG_QUERIES = True
LOG_NOT_FOUND = True

SEARCH_2_STEPS_STEP1_LIMIT = 20
