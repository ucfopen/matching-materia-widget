<?php

namespace Materia;
class Score_Modules_Matching extends Score_Module
{

	public $is_case_sensitive;
	const VALID_CHARS = '/[^\w!@#$%^&*?=\-+<>,\.;:"\'\(\) \t|]/';

	public function __construct($play_id, $inst, $play = null)
	{
		parent::__construct($play_id, $inst, $play);

		if (isset($inst->qset->data['options']['caseSensitive']) && $inst->qset->data['options']['caseSensitive'] == 1)
		{
			$this->is_case_sensitive = true;
		}
		else
		{
			$this->is_case_sensitive = false;
		}
	}

	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$question = $this->questions[$log->item_id];

			if($log->value != '')
			{
				// answer is an audio asset & id
				$givenAnswer = $log->value;
				$expectedAnswer = $question->assets[2];
			}
			else
			{
				// answer is a text answer
				$givenAnswer = $log->text;
				$expectedAnswer = $question->answers[0]['text'];
			}

			$givenAnswer = preg_replace(self::VALID_CHARS, '', $givenAnswer);
			$expectedAnswer = preg_replace(self::VALID_CHARS, '', $expectedAnswer);

			if ( ! $this->is_case_sensitive)
			{
				// we dont care about case, so just convert all to upper
				$givenAnswer = strtoupper($givenAnswer);
				$expectedAnswer = strtoupper($expectedAnswer);
			}

			// trim whitespace
			$givenAnswer = trim($givenAnswer);
			$expectedAnswer = trim($expectedAnswer);

			// check answer
			if ($givenAnswer == $expectedAnswer)
			{
				return 100;
			}
		}

		return 0;
	}
}
