<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Matching
 */
class Test_Score_Modules_Matching extends \Basetest
{

	protected function _get_qset()
	{
		return json_decode('
			{
				"items":[
					{
						"items":[
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"1",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"1",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"2",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"2",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"3",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"3",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"4",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"4",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"5",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"5",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	}
						],
						"name":"",
						"options":{},
						"assets":[],
						"rand":false
					}
				],
				 "name":"",
				 "options":
				 	{
				 		"caseSensitive":false
				 	},
				 "assets":[],
				 "rand":false
			}');
	}

	protected function _makeWidget($version = 8)
	{
		$this->_asAuthor();

		$title = 'MATCHING SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id($version);
		$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];

		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_checkLastChanceCorrect()
	{
		//last chance cadet
		$inst = $this->_makeWidget('Last Chance Cadet');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$log = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$log2 = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$log3 = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$log4 = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$log5 = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$end_log = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, array($log, $log2, $log3, $log4, $log5, $end_log));
		$scores = \Materia\Api::widget_instance_scores_get($inst->id);
		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(100, $this_score[0]['overview']['score']);
	}
	public function test_checkPlainCorrect()
	{
		//last chance cadet
		$inst = $this->_makeWidget('Last Chance Cadet');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$log = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$log2 = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$log3 = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$log4 = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$log5 = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$end_log = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, array($log, $log2, $log3, $log4, $log5, $end_log));
		$scores = \Materia\Api::widget_instance_scores_get($inst->id);
		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(100, $this_score[0]['overview']['score']);
	}

	public function test_checkLastChanceIncorrect()
	{
		//last chance cadet
		$inst = $this->_makeWidget('Matching');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$log = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$log2 = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$log3 = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$log4 = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$log5 = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$end_log = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, array($log, $log2, $log3, $log4, $log5, $end_log));
		$scores = \Materia\Api::widget_instance_scores_get($inst->id);
		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(60, $this_score[0]['overview']['score']);
	}

	public function test_checkPlainIncorrect()
	{
		//last chance cadet
		$inst = $this->_makeWidget('Matching');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$log = json_decode('{
			"text":"2",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$log2 = json_decode('{
			"text":"1",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');
		$log3 = json_decode('{
			"text":"3",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":11
		}');
		$log4 = json_decode('{
			"text":"4",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][3]['id'].'",
			"game_time":11
		}');
		$log5 = json_decode('{
			"text":"5",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][4]['id'].'",
			"game_time":11
		}');
		$end_log = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":12
		}');

		$output = \Materia\Api::play_logs_save($play_session, array($log, $log2, $log3, $log4, $log5, $end_log));
		$scores = \Materia\Api::widget_instance_scores_get($inst->id);
		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(60, $this_score[0]['overview']['score']);
	}
}