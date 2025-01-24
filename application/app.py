from re import S
from time import sleep
from flask import Flask, render_template, request, jsonify
from datetime import datetime
import platform
import os
import pymongo
from pymongo import MongoClient
from forms import TestDBForm


app = Flask(__name__)
app.secret_key = 'dev fao football app'
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

time_start = datetime.now()

bg_color = os.environ.get("BG_COLOR", "white")
mongo_username = os.environ.get("MONGO_USERNAME", "root")
mongo_password = os.environ.get("MONGO_PASSWORD", "example")
mongo_host = os.environ.get("MONGO_HOST", "localhost") 
mongo_port = os.environ.get("MONGO_PORT", "27017")

def get_database(db_name):
    CONNECTION_STRING = f"mongodb://{mongo_username}:{mongo_password}@{mongo_host}:{mongo_port}"
    try:
        client = MongoClient(CONNECTION_STRING, serverSelectionTimeoutMS=5000)
        
        return client[db_name]
    except pymongo.errors.ConnectionFailure as e:
        app.logger.error(f'Failed to connecto to MongoDB: {e}')

@app.route("/")
def home():
    return render_template("start.html", color=bg_color)

@app.route("/test_db", methods=["GET", "POST"])
def test_db_form():
    form = TestDBForm()
    if request.method == 'POST':
        db = get_database('demo_app')
        name = request.form["name"]
        message = request.form["message"]
        now = datetime.now()
        data = {'name': name, 'message': message, 'timestamp': now.isoformat()}
        result = db.test_data.insert_one(data)
        app.logger.info(f'Message: {data}')

        return render_template('form_test.html', form=form, color=bg_color)
    else:
        return render_template('form_test.html', form=form, color=bg_color)

@app.route("/color")
def color():
    now = datetime.now()
    json_value = {
        "color": bg_color,
        "time": now.isoformat(),
        "system_info": "-".join([platform.system(), platform.platform()]),
        "hostname": platform.node(),
        "python": platform.python_version()
    }
    return jsonify(json_value)

@app.route("/issue")
def issue():
    json_value = {
        "time": datetime.now().isoformat()
    }
    if os.getenv('FAIL_FLAG'):
        if os.getenv('FAIL_FLAG').lower() == 'true':
            app.logger.error('Enviroment variable: FAIL_FLAG is set to True')
            json_value["message"] = "Issue is not fixed. Check appliaction logs for more information"
            json_value["fixed"] = "false"

            return jsonify(json_value)
        else:
            app.logger.info('Enviroment variable: FAIL_FLAG is set to False')
            json_value["message"] = "Issue is fixed"
            json_value["fixed"] = "true"

            return jsonify(json_value)
    else:
        app.logger.error('Enviroment variable: FAIL_FLAG is not set')
        json_value["message"] = "Issue is not fixed. Check appliaction logs for more information"
        json_value["fixed"] = "false"

        return jsonify(json_value)

@app.route("/db_message", methods=["GET"])
def db_message():
    if request.method == 'GET':
        try:
            db = get_database('demo_app')
            limit_url = request.args.get('limit', default=10, type=int)
            messages = db.test_data.find({}, {"_id": 0}).sort( [['_id', -1]] ).limit(limit_url)
            data = [message for message in messages]
        
            return jsonify({"result": data, "succeed": True})
        except pymongo.errors.ServerSelectionTimeoutError as e:
            app.logger.error(f'Failed to connecto to MongoDB: {e}')

            return jsonify({"result": str(e), "succeed": False})
@app.route("/healthz")
def healthz():
    return "OK"

@app.route("/healthx")
def healthx():
    sleep(1)
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)