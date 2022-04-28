import firebase_admin
from firebase_admin import firestore

example_doc = {
    "start_time": 1651169721,
    "end_time": 1651169721,
    "is_real": True,
    "is_holo": False,
    "acc": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "battery": {
        "timestamps": [1650556938223033856],
        "value": [1.0]
    },
    "attitude": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472],
        "w": [-9.895472]
    },
    "gps": {
        "timestamps": [1650556938223033856],
        "lat": [-0.001647],
        "long": [-0.001647],
        "horizontal_acc": [-0.001647],
        "altitude": [-0.001647],
        "building_floor": [-0.001647],
        "vertical_acc": [-0.001647],
    },
    "gravity": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "gyroscope": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "gyroscope_uncal": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "heading": {
        "timestamps": [1650556938223033856],
        "angle": [1.0]
    },
    "height": {
        "timestamps": [1650556938223033856],
        "relative_altitude": [1.0]
    },
    "line_acc": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "magnet": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "magnet_uncal": {
        "timestamps": [1650556938223033856],
        "x": [-0.001647],
        "y": [0.044907],
        "z": [-9.895472]
    },
    "pressure": {
        "timestamps": [1650556938223033856],
        "value": [-0.001647],
    }
}


if __name__ == "__main__":
    firebase_admin.initialize_app()
    db = firestore.client()
    db.collection("haptic").document("test_doc").set(example_doc)
